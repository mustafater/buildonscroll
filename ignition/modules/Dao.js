const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("DaoleModule", (m) => {

  const DaoContract = m.contract("Dao", []);

  return { DaoContract };
});