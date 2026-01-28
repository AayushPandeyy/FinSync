// import 'package:finance_tracker/models/Subscription.dart';
// import 'package:finance_tracker/utilities/CurrencyService.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class SubscriptionTile extends StatefulWidget {
//   final Subscription subscription;

//   const SubscriptionTile({super.key, required this.subscription});

//   @override
//   State<SubscriptionTile> createState() => _SubscriptionTileState();
// }

// class _SubscriptionTileState extends State<SubscriptionTile> {
//   String _currencySymbol = 'Rs';

//   @override
//   void initState() {
//     super.initState();
//     _loadCurrencySymbol();
//   }

//   Future<void> _loadCurrencySymbol() async {
//     final symbol = await CurrencyService.getCurrencySymbol();
//     if (mounted) {
//       setState(() {
//         _currencySymbol = symbol;
//       });
//     }
//   }

//   void _showSubscriptionDetails(BuildContext context) {
//     final size = MediaQuery.sizeOf(context);
//     final width = size.width;
    
//     final daysUntilBilling = widget.subscription.nextBillingDate.difference(DateTime.now()).inDays;
    
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: Colors.transparent,
//         child: Container(
//           constraints: BoxConstraints(maxWidth: width * 0.9),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               // Header with icon and close button
//               Container(
//                 padding: EdgeInsets.all(width * 0.05),
//                 decoration: BoxDecoration(
//                   borderRadius: const BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: width * 0.15,
//                       height: width * 0.15,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
                      
//                     ),
//                     SizedBox(width: width * 0.04),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.subscription.name,
//                             style: TextStyle(
//                               fontSize: width * 0.05,
//                               fontWeight: FontWeight.w700,
//                               color: const Color(0xFF1A1A1A),
//                             ),
//                           ),
//                           SizedBox(height: width * 0.01),
//                           Text(
//                             subscription.category,
//                             style: TextStyle(
//                               fontSize: width * 0.035,
//                               color: const Color(0xFF666666),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       onPressed: () => Navigator.pop(context),
//                       icon: const Icon(Icons.close, color: Color(0xFF666666)),
//                       padding: EdgeInsets.zero,
//                       constraints: const BoxConstraints(),
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Details
//               Padding(
//                 padding: EdgeInsets.all(width * 0.05),
//                 child: Column(
//                   children: [
//                     // Amount
//                     _buildDetailRow(
//                       'Amount',
//                       '$_currencySymbol ${widget.subscription.amount}',
//                       Icons.payments_outlined,
//                       width,
//                     ),
//                     SizedBox(height: width * 0.04),
                    
//                     // Billing Cycle
//                     _buildDetailRow(
//                       'Billing Cycle',
//                       widget.subscription.billingCycle,
//                       Icons.sync_alt,
//                       width,
//                     ),
//                     SizedBox(height: width * 0.04),
                    
//                     // Next Billing Date
//                     _buildDetailRow(
//                       'Next Billing',
//                       DateFormat('d MMM yyyy').format(subscription.nextBillingDate),
//                       Icons.calendar_today,
//                       width,
//                     ),
//                     SizedBox(height: width * 0.04),
                    
//                     // Days until billing
//                     _buildDetailRow(
//                       'Days Until Billing',
//                       daysUntilBilling <= 0 
//                           ? 'Today' 
//                           : '$daysUntilBilling ${daysUntilBilling == 1 ? 'day' : 'days'}',
//                       Icons.access_time,
//                       width,
//                       valueColor: daysUntilBilling <= 7 
//                           ? const Color(0xFFF57C00) 
//                           : const Color(0xFF06D6A0),
//                     ),
                    
//                     SizedBox(height: width * 0.05),
                    
//                     // Action buttons
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               // TODO: Implement edit functionality
//                             },
//                             style: OutlinedButton.styleFrom(
//                               padding: EdgeInsets.symmetric(vertical: width * 0.035),
//                               side: const BorderSide(
//                                 color: Color(0xFF4A90E2),
//                                 width: 1,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             icon: const Icon(
//                               Icons.edit,
//                               size: 18,
//                               color: Color(0xFF4A90E2),
//                             ),
//                             label: const Text(
//                               'Edit',
//                               style: TextStyle(
//                                 color: Color(0xFF4A90E2),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: width * 0.03),
//                         Expanded(
//                           child: OutlinedButton.icon(
//                             onPressed: () {
//                               Navigator.pop(context);
//                               // TODO: Implement delete functionality
//                               _showDeleteConfirmation(context);
//                             },
//                             style: OutlinedButton.styleFrom(
//                               padding: EdgeInsets.symmetric(vertical: width * 0.035),
//                               side: const BorderSide(
//                                 color: Color(0xFFE63946),
//                                 width: 1,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             icon: const Icon(
//                               Icons.delete_outline,
//                               size: 18,
//                               color: Color(0xFFE63946),
//                             ),
//                             label: const Text(
//                               'Delete',
//                               style: TextStyle(
//                                 color: Color(0xFFE63946),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(
//     String label, 
//     String value, 
//     IconData icon, 
//     double width,
//     {Color? valueColor}
//   ) {
//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.all(width * 0.025),
//           decoration: BoxDecoration(
//             color: const Color(0xFFF8F8FA),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Icon(
//             icon,
//             size: width * 0.045,
//             color: const Color(0xFF666666),
//           ),
//         ),
//         SizedBox(width: width * 0.03),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: width * 0.032,
//                   color: const Color(0xFF999999),
//                   fontWeight: FontWeight.w400,
//                 ),
//               ),
//               SizedBox(height: width * 0.008),
//               Text(
//                 value,
//                 style: TextStyle(
//                   fontSize: width * 0.04,
//                   color: valueColor ?? const Color(0xFF1A1A1A),
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   void _showDeleteConfirmation(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: const Text(
//           'Delete Subscription',
//           style: TextStyle(
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF1A1A1A),
//           ),
//         ),
//         content: Text(
//           'Are you sure you want to delete ${widget.subscription.name}?',
//           style: const TextStyle(
//             color: Color(0xFF666666),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(
//                 color: Color(0xFF666666),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // TODO: Implement delete logic
//             },
//             child: const Text(
//               'Delete',
//               style: TextStyle(
//                 color: Color(0xFFE63946),
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.sizeOf(context);
//     final width = size.width;

//     final daysUntilBilling = widget.subscription.nextBillingDate.difference(DateTime.now()).inDays;
//     final isUpcoming = daysUntilBilling <= 7;

//     return GestureDetector(
//       onTap: () => _showSubscriptionDetails(context),
//       child: Container(
//         margin: EdgeInsets.symmetric(
//           horizontal: width * 0.04,
//           vertical: width * 0.015,
//         ),
//         padding: EdgeInsets.all(width * 0.04),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           border: Border.all(
//             color: const Color(0xFFE5E5E5),
//             width: 1,
//           ),
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Column(
//           children: [
//             // Main content row
//             Row(
//               children: [
//                 // Icon
//                 Container(
//                   width: width * 0.12,
//                   height: width * 0.12,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
                  
//                 ),

//                 SizedBox(width: width * 0.04),

//                 // Details
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         subscription.name,
//                         style: TextStyle(
//                           fontSize: width * 0.042,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF1A1A1A),
//                         ),
//                       ),
//                       SizedBox(height: width * 0.01),
//                       Row(
//                         children: [
//                           Text(
//                             subscription.category,
//                             style: TextStyle(
//                               fontSize: width * 0.032,
//                               color: const Color(0xFF999999),
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                           SizedBox(width: width * 0.02),
//                           Container(
//                             width: 3,
//                             height: 3,
//                             decoration: const BoxDecoration(
//                               color: Color(0xFFCCCCCC),
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                           SizedBox(width: width * 0.02),
//                           Text(
//                             widget.subscription.billingCycle,
//                             style: TextStyle(
//                               fontSize: width * 0.032,
//                               color: const Color(0xFF999999),
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Amount
//                 Text(
//                   '$_currencySymbol ${widget.subscription.amount}',
//                   style: TextStyle(
//                     color: const Color(0xFF1A1A1A),
//                     fontSize: width * 0.042,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),

//             // Next billing date row
//             if (isUpcoming) ...[
//               SizedBox(height: width * 0.03),
//               Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: width * 0.03,
//                   vertical: width * 0.02,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFFFF3E0),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(
//                       Icons.access_time,
//                       size: width * 0.035,
//                       color: const Color(0xFFF57C00),
//                     ),
//                     SizedBox(width: width * 0.015),
//                     Text(
//                       'Due ${DateFormat("d MMM").format(subscription.nextBillingDate)}',
//                       style: TextStyle(
//                         fontSize: width * 0.032,
//                         color: const Color(0xFFF57C00),
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ] else ...[
//               SizedBox(height: width * 0.02),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.calendar_today,
//                     size: width * 0.03,
//                     color: const Color(0xFF999999),
//                   ),
//                   SizedBox(width: width * 0.015),
//                   Text(
//                     'Next: ${DateFormat("d MMM yyyy").format(widget.subscription.nextBillingDate)}',
//                     style: TextStyle(
//                       fontSize: width * 0.03,
//                       color: const Color(0xFF999999),
//                       fontWeight: FontWeight.w400,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }