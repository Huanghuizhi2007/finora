import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  );
  const token = authHeader.replace("Bearer ", "");
  const { data: user, error: userError } = await supabase.auth.getUser(token);
  if (userError || !user.user) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("is_admin")
    .eq("id", user.user.id)
    .maybeSingle();
  if (!profile?.is_admin) {
    return new Response(JSON.stringify({ error: "forbidden" }), { status: 403 });
  }

  const [users, active, newUsers] = await Promise.all([
    supabase.from("profiles").select("id", { count: "exact", head: true }),
    supabase.from("app_events").select("user_id", { count: "exact", head: true }).gte("created_at", new Date(Date.now() - 7 * 86400000).toISOString()),
    supabase.from("profiles").select("id", { count: "exact", head: true }).gte("created_at", new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString()),
  ]);

  return new Response(
    JSON.stringify({
      totalUsers: users.count ?? 0,
      activeUsers: active.count ?? 0,
      newThisMonth: newUsers.count ?? 0,
      status: "normal",
    }),
    { headers: { "Content-Type": "application/json" } },
  );
});
