import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );
  const token = authHeader.replace("Bearer ", "");
  const { data: user, error: userError } = await supabase.auth.getUser(token);
  if (userError || !user.user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const body = await req.json();
  const targetId = body?.userId;
  if (!targetId || targetId !== user.user.id) {
    return new Response(JSON.stringify({ error: "forbidden" }), { status: 403 });
  }

  const { error } = await supabase.auth.admin.deleteUser(targetId);
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ ok: true }));
});
