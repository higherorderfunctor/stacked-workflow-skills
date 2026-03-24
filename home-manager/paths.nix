# Resolved paths to skill and reference directories.
#
# Separated from the module so flake.nix lib can also reference these paths
# without importing the full module.
{
  referencesDir = ../references;
  skillsDir = ../skills;
}
