class MarketplaceItem {
  final String id;
  final String title;
  final int price;
  final String location;
  final String imageUrl;
  final DateTime createdAt;
  MarketplaceItem({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.createdAt,
  });
}
