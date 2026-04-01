# SakayPo Admin Account Setup Guide

## 🔧 Creating Your First Admin Account

Since there's no bootstrap UI to create the first admin, you'll create it manually in Supabase. Follow these steps:

### Step 1: Sign up normally
1. Go to `https://[your-domain]/pages/register.html`
2. Create an account with your email and password
3. Select **Passenger** or **Driver** as your role (doesn't matter)
4. Submit — your account will be created with status `pending`

### Step 2: Manually promote to admin in Supabase SQL
Once your account is created, go to your **Supabase Dashboard**:

1. Open **SQL Editor** (in the left sidebar)
2. Create a new query
3. **Copy and paste this SQL**, replacing `your-admin-email@example.com` with the email you just registered with:

```sql
UPDATE public.profiles
SET role = 'admin', status = 'approved'
WHERE email = 'your-admin-email@example.com';
```

4. Click **Run** (blue button)

### Step 3: Sign in to Admin Panel
1. Go to `https://[your-domain]/pages/login.html`
2. Sign in with your admin email and password
3. You'll be automatically routed to `/pages/admin.html` ✅

---

## 📧 Setting Up Email Notifications (Optional but Recommended)

When you approve or reject accounts, SakayPo can send automated emails to users.

### Step 1: Create a free EmailJS account
1. Go to **https://emailjs.com**
2. Click **Sign Up** (free tier is available)
3. Complete the registration

### Step 2: Get your EmailJS credentials
After signing up, you'll see your dashboard. Collect:
- **Public Key** (top right, "User ID" or under "Account > Account Info")
- **Service ID** (under "Email Services" tab, e.g., `service_xxxx`)
- **Template ID for Approved emails** (under "Email Templates" tab)
- **Template ID for Rejected emails** (under "Email Templates" tab)

> If templates don't exist, create two new templates:
> - Name: `approved_account_template`
> - Name: `rejected_account_template`

### Step 3: Connect a Gmail account (simplest option)
In EmailJS **Email Services** tab:
1. Click **Add Service**
2. Select **Gmail**
3. Follow the prompts to authenticate your Gmail account
4. Note the **Service ID** generated (e.g., `service_gmail_xxxxx`)

### Step 4: Configure Admin Panel
Open [pages/admin.html](pages/admin.html) and find this section at the top:

```javascript
const EMAILJS_PUBLIC_KEY = 'YOUR_EMAILJS_PUBLIC_KEY_HERE';
const EMAILJS_SERVICE_ID = 'YOUR_EMAILJS_SERVICE_ID_HERE';
const EMAILJS_APPROVED_TEMPLATE = 'YOUR_APPROVED_TEMPLATE_ID_HERE';
const EMAILJS_REJECTED_TEMPLATE = 'YOUR_REJECTED_TEMPLATE_ID_HERE';
```

**Replace placeholders with your actual IDs from EmailJS.**

Example:
```javascript
const EMAILJS_PUBLIC_KEY = 'abc123def456ghi789';
const EMAILJS_SERVICE_ID = 'service_gmail_xyz123';
const EMAILJS_APPROVED_TEMPLATE = 'template_approved_123';
const EMAILJS_REJECTED_TEMPLATE = 'template_rejected_456';
```

### Step 5: Test it
1. Go back to your admin panel
2. Approve or reject a pending user
3. Check their inbox — if set up correctly, they'll receive an email!

---

## 🚨 If Email Doesn't Send

The system gracefully degrades: even if EmailJS is not configured, the approval/rejection still works. Emails are optional.

Check browser console (`F12` → **Console**) for errors. If you see:
- `"Email send failed (check EmailJS config)"` → EmailJS is configured but there's an issue
- No warning → EmailJS is not configured (normal, system still works)

---

## 👥 Creating More Admin Accounts

Once you have one admin, you can make more via the SQL query (same process), or:

**Future enhancement**: Add a UI in the admin panel to toggle roles/status directly (not yet built).

---

## 📋 Checklist

- [ ] I've registered my account at `/pages/register.html`
- [ ] I've run the SQL query to promote myself to admin
- [ ] I can log in to `/pages/admin.html` and see the user list
- [ ] (Optional) I've set up EmailJS and configured the credentials
- [ ] (Optional) I've tested approving a user and received an email

---

## 🔐 Security Notes

- **First admin**: Created manually via SQL — keep this email safe
- **RLS Policies**: Admins can approve/reject any user (see `supabase-schema.sql`)
- **Password reset**: Use Supabase "Recover password" link (not yet in UI, but works via email)

---

## 📞 Troubleshooting

| Problem | Solution |
|---------|----------|
| "Account not found" on login | Make sure you registered first, then ran the SQL update |
| Admin dashboard is blank | Check your Supabase URL and key in `js/supabase.js` |
| Email isn't sending | Check EmailJS credentials, or leave it unconfigured (system still works) |
| Role won't update in admin UI | Wait a few seconds — realtime sync takes a moment |

---

**Next steps**: Deploy to Vercel + connect to Supabase production. Then promote your production admin the same way.
