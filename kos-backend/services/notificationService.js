//const nodemailer = require("nodemailer");
//const axios = require("axios");
//const db = require("../config/db");
////const config = require("../config/notificationConfig");
//
//const getOwnerByKosId = (kosId, callback) => {
//  const sql = `
//    SELECT o.id, o.email, o.phone
//    FROM kos k
//    JOIN owners o ON k.owner_id = o.id
//    WHERE k.id = ?
//  `;
//  db.query(sql, [kosId], callback);
//};
//
//// ─── Email ───────────────────────────────────────────────
//const transporter = nodemailer.createTransport({
//  service: "gmail",
//  auth: {
//    user: config.email.user,
//    pass: config.email.pass,
//  },
//});
//
//const sendEmail = async (to, subject, text) => {
//  try {
//    await transporter.sendMail({
//      from: `"Kos Manager" <${config.email.user}>`,
//      to,
//      subject,
//      text,
//    });
//    console.log(`[Email] ✅ Sent to ${to}`);
//  } catch (err) {
//    console.error(`[Email] ❌ Failed to ${to}:`, err.message);
//  }
//};
//
//// ─── WhatsApp (Fonnte) ────────────────────────────────────
//const sendWhatsApp = async (phone, message) => {
//  try {
//    await axios.post(
//      "https://api.fonnte.com/send",
//      { target: phone, message },
//      { headers: { Authorization: config.fonnte.token } }
//    );
//    console.log(`[WhatsApp] ✅ Sent to ${phone}`);
//  } catch (err) {
//    console.error(`[WhatsApp] ❌ Failed to ${phone}:`, err.message);
//  }
//};
//
//// ─── In-app ───────────────────────────────────────────────
//const saveNotification = (recipientType, recipientId, title, message, type) => {
//  const sql = `
//    INSERT INTO notifications (recipient_type, recipient_id, title, message, type)
//    VALUES (?, ?, ?, ?, ?)
//  `;
//  db.query(sql, [recipientType, recipientId, title, message, type], (err) => {
//    if (err) console.error("[Notification] ❌ Failed to save:", err.message);
//  });
//};
//
//// ─── Notify tenant ────────────────────────────────────────
//const notifyTenant = async (tenant, title, message, type) => {
//  // In-app
//  saveNotification("tenant", tenant.tenant_id, title, message, type);
//
//  // Email
//  if (tenant.email) await sendEmail(tenant.email, title, message);
//
//  // WhatsApp
//  if (tenant.phone) await sendWhatsApp(tenant.phone, `*${title}*\n\n${message}`);
//};
//
//// ─── Notify owner ─────────────────────────────────────────
//const notifyOwner = async (owner, title, message, type) => {
//  // In-app
//  saveNotification("owner", owner.id, title, message, type);
//
//  // Email
//  if (owner.email) await sendEmail(owner.email, title, message);
//
//  // WhatsApp
//  if (owner.phone) await sendWhatsApp(owner.phone, `*${title}*\n\n${message}`);
//};
//
//// ─── Bill generated ───────────────────────────────────────
//const onBillGenerated = async (tenant, bill) => {
//  const title = "Tagihan Baru Tersedia";
//  const message =
//    `Halo ${tenant.tenant_name},\n\n` +
//    `Tagihan bulan ${bill.billing_month} telah dibuat.\n` +
//    `Total: Rp${bill.total_amount.toLocaleString("id-ID")}\n` +
//    `Jatuh tempo: ${bill.due_date}\n\n` +
//    `Harap segera lakukan pembayaran. Terima kasih!`;
//
//  await notifyTenant(
//    { ...tenant, tenant_id: tenant.tenant_id },
//    title,
//    message,
//    "bill_generated"
//  );
//  getOwnerByKosId(tenant.kos_id, (err, owners) => {
//    if (err || !owners.length) return;
//    const ownerTitle = "Tagihan Dibuat";
//    const ownerMessage = `Tagihan ${tenant.tenant_name} bulan ${bill.billing_month} telah dibuat. Total: Rp${bill.total_amount.toLocaleString("id-ID")}`;
//    saveNotification("owner", owners[0].id, ownerTitle, ownerMessage, "bill_generated");
//  });
//};
//
//// ─── Due soon (3 days before) ─────────────────────────────
//const onDueSoon = async (tenant, bill) => {
//  const title = "Tagihan Jatuh Tempo 3 Hari Lagi";
//  const message =
//    `Halo ${tenant.tenant_name},\n\n` +
//    `Tagihan bulan ${bill.billing_month} akan jatuh tempo pada ${bill.due_date}.\n` +
//    `Total: Rp${parseFloat(bill.total_amount).toLocaleString("id-ID")}\n\n` +
//    `Segera lakukan pembayaran untuk menghindari denda. Terima kasih!`;
//
//  await notifyTenant(
//    { ...tenant, tenant_id: tenant.tenant_id },
//    title,
//    message,
//    "due_soon"
//  );
//};
//
//// ─── Overdue ──────────────────────────────────────────────
//const onOverdue = async (tenant, bill, owner) => {
//  // Notify tenant
//  const tenantTitle = "Tagihan Anda Terlambat";
//  const tenantMessage =
//    `Halo ${tenant.tenant_name},\n\n` +
//    `Tagihan bulan ${bill.billing_month} belum dibayar dan telah melewati jatuh tempo.\n` +
//    `Total + Denda: Rp${parseFloat(bill.total_amount).toLocaleString("id-ID")}\n\n` +
//    `Harap segera hubungi pemilik kos. Terima kasih!`;
//
//  await notifyTenant(
//    { ...tenant, tenant_id: tenant.tenant_id },
//    tenantTitle,
//    tenantMessage,
//    "overdue"
//  );
//
//  // Notify owner
//  if (owner) {
//    const ownerTitle = "Tenant Terlambat Bayar";
//    const ownerMessage =
//      `${tenant.tenant_name} belum membayar tagihan bulan ${bill.billing_month}.\n` +
//      `Total + Denda: Rp${parseFloat(bill.total_amount).toLocaleString("id-ID")}\n` +
//      `Sudah ${bill.days_late} hari terlambat.`;
//
//    await notifyOwner(owner, ownerTitle, ownerMessage, "overdue");
//  }
//};
//
//module.exports = { onBillGenerated, onDueSoon, onOverdue };