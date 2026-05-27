class LimaPadelClub {
  const LimaPadelClub({
    required this.name,
    required this.address,
    required this.city,
    required this.district,
  });

  final String name;
  final String address;
  final String city;
  final String district;
}

const List<LimaPadelClub> limaPadelClubDetails = [
  LimaPadelClub(
    name: 'One Padel Olguin',
    address: 'Av. Manuel Olguin 325',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'One Padel Trigal',
    address: 'Av. El Derby 254',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'One Padel Naval',
    address: 'Av. Manuel Olguin 901',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'Los Inkas Padel',
    address: 'Av. El Golf Los Incas 376',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'Pro Padel',
    address: 'Av. La Molina 1104',
    city: 'Lima',
    district: 'La Molina',
  ),
  LimaPadelClub(
    name: 'Padel 360',
    address: 'Av. Javier Prado Este 5600',
    city: 'Lima',
    district: 'La Molina',
  ),
  LimaPadelClub(
    name: 'Padel House',
    address: 'Av. Primavera 120',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'Arena Padel',
    address: 'Av. Alameda Sur 1530',
    city: 'Lima',
    district: 'Chorrillos',
  ),
  LimaPadelClub(
    name: 'Padel Zone',
    address: 'Av. Caminos del Inca 257',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'Padel Point',
    address: 'Av. Universitaria 1801',
    city: 'Lima',
    district: 'San Miguel',
  ),
  LimaPadelClub(
    name: 'Padel Surco',
    address: 'Av. La Encalada 1010',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'Padel La Molina',
    address: 'Av. Raul Ferrero 1595',
    city: 'Lima',
    district: 'La Molina',
  ),
  LimaPadelClub(
    name: 'Club Terrazas Padel',
    address: 'Mal. 28 de Julio 390',
    city: 'Lima',
    district: 'Miraflores',
  ),
  LimaPadelClub(
    name: 'Padel Nuestro Lima',
    address: 'Av. Primavera 1878',
    city: 'Lima',
    district: 'Santiago de Surco',
  ),
  LimaPadelClub(
    name: 'Lima Padel Center',
    address: 'Av. Separadora Industrial 1980',
    city: 'Lima',
    district: 'La Molina',
  ),
  LimaPadelClub(
    name: 'Costa Verde Padel',
    address: 'Circuito de Playas 150',
    city: 'Lima',
    district: 'San Miguel',
  ),
  LimaPadelClub(
    name: 'Padel Club San Isidro',
    address: 'Av. Guardia Civil 727',
    city: 'Lima',
    district: 'San Isidro',
  ),
  LimaPadelClub(
    name: 'Padel Norte',
    address: 'Av. Alfredo Mendiola 3698',
    city: 'Lima',
    district: 'Independencia',
  ),
  LimaPadelClub(
    name: 'Padel Barranco',
    address: 'Av. República de Panamá 220',
    city: 'Lima',
    district: 'Barranco',
  ),
  LimaPadelClub(
    name: 'Padel Miraflores',
    address: 'Av. Petit Thouars 5356',
    city: 'Lima',
    district: 'Miraflores',
  ),
  LimaPadelClub(
    name: 'Padel San Borja',
    address: 'Av. San Borja Norte 996',
    city: 'Lima',
    district: 'San Borja',
  ),
];

final List<String> limaPadelClubs = [
  for (final club in limaPadelClubDetails) club.name,
];
