// Creates a new rep (auth user + profile via DB trigger).
// Admin-only: verifies the caller's access token belongs to an admin before creating.
// Requires env var SUPABASE_SERVICE_KEY (service_role / secret key) set in Netlify.

const SUPABASE_URL  = 'https://bxlpoxqckfrikvjhbcju.supabase.co';
const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4bHBveHFja2ZyaWt2amhiY2p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2ODEyMzgsImV4cCI6MjA5ODI1NzIzOH0.Jrcxy3J-BL3hOat5fzPoq-XHYYJABgRhjhOQDCBILjw';

const json = (statusCode, obj) => ({
  statusCode,
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(obj),
});

exports.handler = async (event) => {
  if (event.httpMethod !== 'POST') return json(405, { error: 'Method not allowed' });

  const SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
  if (!SERVICE_KEY) {
    return json(500, { error: 'Server not configured: SUPABASE_SERVICE_KEY is missing in Netlify env vars.' });
  }

  // 1. caller token
  const authHeader = event.headers.authorization || event.headers.Authorization || '';
  const token = authHeader.replace(/^Bearer\s+/i, '').trim();
  if (!token) return json(401, { error: 'Not authenticated.' });

  try {
    // 2. verify the token → who is calling
    const userRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SUPABASE_ANON, Authorization: `Bearer ${token}` },
    });
    if (!userRes.ok) return json(401, { error: 'Invalid or expired session.' });
    const caller = await userRes.json();

    // 3. confirm the caller is an admin (query reps with service key, bypassing RLS)
    const roleRes = await fetch(
      `${SUPABASE_URL}/rest/v1/reps?id=eq.${caller.id}&select=role`,
      { headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${SERVICE_KEY}` } }
    );
    const rows = await roleRes.json();
    if (!Array.isArray(rows) || rows[0]?.role !== 'admin') {
      return json(403, { error: 'Admins only.' });
    }

    // 4. validate input
    const { name, email, phone, password, role } = JSON.parse(event.body || '{}');
    if (!name || !email || !password) return json(400, { error: 'Name, email and password are required.' });
    const newRole = role === 'admin' ? 'admin' : 'salesperson';

    // 5. create the auth user (auto-confirmed); the DB trigger creates the reps row
    const createRes = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
      method: 'POST',
      headers: {
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
        user_metadata: { name, phone: phone || null, role: newRole },
      }),
    });
    const created = await createRes.json();
    if (!createRes.ok) {
      return json(createRes.status, { error: created.msg || created.error_description || created.error || 'Could not create user.' });
    }

    return json(200, { ok: true, id: created.id, email: created.email });
  } catch (err) {
    return json(500, { error: err.message });
  }
};
