/// User entitlement tiers
enum Entitlement {
  free(
    maxDevices: 2,
    allModes: true,
    aarExport: false,
    allMapRegions: false,
    allThemes: false,
    fullFieldLink: false,
  ),
  pro(
    maxDevices: 2,
    allModes: true,
    aarExport: true,
    allMapRegions: true,
    allThemes: true,
    fullFieldLink: false,
  ),
  proLink(
    maxDevices: 8,
    allModes: true,
    aarExport: true,
    allMapRegions: true,
    allThemes: true,
    fullFieldLink: true,
  ),
  team(
    maxDevices: 8,
    allModes: true,
    aarExport: true,
    allMapRegions: true,
    allThemes: true,
    fullFieldLink: true,
  );

  final int maxDevices;
  final bool allModes;
  final bool aarExport;
  final bool allMapRegions;
  final bool allThemes;
  final bool fullFieldLink;

  const Entitlement({
    required this.maxDevices,
    required this.allModes,
    required this.aarExport,
    required this.allMapRegions,
    required this.allThemes,
    required this.fullFieldLink,
  });
}
