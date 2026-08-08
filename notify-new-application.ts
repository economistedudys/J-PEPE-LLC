// Supabase Edge Function: notify-new-application
// Sends an email to the company whenever a new candidate profile is created or updated.

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const record = payload.record;

    const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY");

    const emailBody = `
      <h2>New candidate activity — J Pepe LLC</h2>
      <p><strong>Name:</strong> ${record.full_name || "(not provided)"}</p>
      <p><strong>Email:</strong> ${record.email || "(not provided)"}</p>
      <p><strong>Phone:</strong> ${record.phone || "(not provided)"}</p>
      <p><strong>Category:</strong> ${record.category || "(not provided)"}</p>
      <p><strong>Note:</strong> ${record.cover_note || "(none)"}</p>
      <p><strong>Resume:</strong> ${record.resume_url ? `<a href="${record.resume_url}">View resume</a>` : "(not uploaded)"}</p>
      <hr>
      <p style="color:#888;font-size:12px;">This is an automated notification from your Supabase candidate database.</p>
    `;

    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${RESEND_API_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: "J Pepe LLC <onboarding@resend.dev>",
        to: ["contact@jpepellc.com"],
        subject: `New candidate: ${record.full_name || record.email}`,
        html: emailBody,
      }),
    });

    const data = await res.json();

    return new Response(JSON.stringify({ ok: true, resend: data }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ ok: false, error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
