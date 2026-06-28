/* ozxpress-routes — shared Supabase client + auth helpers
   Loaded after the supabase-js UMD bundle (window.supabase).
   Exposes window.ozAuth. */
(function () {
  const SUPABASE_URL  = 'https://bxlpoxqckfrikvjhbcju.supabase.co';
  const SUPABASE_ANON = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4bHBveHFja2ZyaWt2amhiY2p1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2ODEyMzgsImV4cCI6MjA5ODI1NzIzOH0.Jrcxy3J-BL3hOat5fzPoq-XHYYJABgRhjhOQDCBILjw';

  const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON);

  const ozAuth = {
    client,

    async getSession() {
      const { data } = await client.auth.getSession();
      return data.session;
    },

    async getMyProfile() {
      const session = await this.getSession();
      if (!session) return null;
      const { data, error } = await client
        .from('reps').select('*').eq('id', session.user.id).single();
      if (error) { console.error('profile load error:', error.message); return null; }
      return data;
    },

    /* Gate a page.
       requiredRole: null  → any logged-in user
                     'admin' → admins only (non-admins bounced to index.html)
       Redirects to login.html if not authenticated / inactive.
       Returns the profile on success, null if it redirected. */
    async requireAuth(requiredRole) {
      const session = await this.getSession();
      if (!session) { location.href = 'login.html'; return null; }
      const profile = await this.getMyProfile();
      if (!profile || profile.active === false) { await this.signOut(); return null; }
      if (requiredRole === 'admin' && profile.role !== 'admin') {
        location.href = 'index.html';
        return null;
      }
      return profile;
    },

    async signIn(email, password) {
      return client.auth.signInWithPassword({ email, password });
    },

    async signOut() {
      await client.auth.signOut();
      location.href = 'login.html';
    },
  };

  window.ozAuth = ozAuth;
})();
