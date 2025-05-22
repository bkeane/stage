const resources = JSON.parse(process.env.RESOURCES);
const stage = '${{ inputs.stage }}';
const account = '${{ inputs.account }}';
// Validate resources[account] exists
if (!(account in resources)) {
  console.error('Invalid account name given: ' + account);
  console.error('Valid accounts are: ' + Object.keys(resources).join(', '));
  process.exit(1);
}
// Validate resources[account][stage] exists
if (!(stage in resources[account])) {
  console.error('Invalid stage name given: ' + stage);
  console.error('Valid stages for account ' + account + ' are: ' + Object.keys(resources[account]).join(', '));
  process.exit(1);
}
// Validate resources[account][stage].role_arn is not null
if (resources[account][stage].role_arn == null) {
  console.error('No role arn found for account ' + account + ' and stage ' + stage);
  process.exit(1);
}
core.setOutput('role_arn', resources[account][stage].role_arn);