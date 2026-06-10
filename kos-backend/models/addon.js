const db = require("../config/db");

const Addon = {
  // Create addon for a kos
  create: (data, callback) => {
    const sql = "INSERT INTO addons (kos_id, name, price) VALUES (?, ?, ?)";
    db.query(sql, [data.kos_id, data.name, data.price], callback);
  },

  // Get all addons for a kos
  findByKosId: (kosId, callback) => {
    const sql = "SELECT * FROM addons WHERE kos_id = ?";
    db.query(sql, [kosId], callback);
  },

  // Delete an addon
  delete: (id, callback) => {
    const sql = "DELETE FROM addons WHERE id = ?";
    db.query(sql, [id], callback);
  },

  // Assign addon to tenant
  assignToTenant: (tenantId, addonId, callback) => {
    const sql = "INSERT INTO tenant_addons (tenant_id, addon_id) VALUES (?, ?)";
    db.query(sql, [tenantId, addonId], callback);
  },

  // Remove addon from tenant
  removeFromTenant: (tenantId, addonId, callback) => {
    const sql = "DELETE FROM tenant_addons WHERE tenant_id = ? AND addon_id = ?";
    db.query(sql, [tenantId, addonId], callback);
  },

  // Get all addons assigned to a tenant
  findByTenantId: (tenantId, callback) => {
    const sql = `
      SELECT a.*, ta.assigned_at
      FROM tenant_addons ta
      JOIN addons a ON ta.addon_id = a.id
      WHERE ta.tenant_id = ?
    `;
    db.query(sql, [tenantId], callback);
  },

  // Get total addon price for a tenant (used in billing)
  getTotalAddonPrice: (tenantId, callback) => {
    const sql = `
      SELECT COALESCE(SUM(a.price), 0) as total
      FROM tenant_addons ta
      JOIN addons a ON ta.addon_id = a.id
      WHERE ta.tenant_id = ?
    `;
    db.query(sql, [tenantId], callback);
  },
};

module.exports = Addon;