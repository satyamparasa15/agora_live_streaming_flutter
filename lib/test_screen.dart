// import 'package:flutter/material.dart';
//
// class TestScreen extends StatefulWidget {
//   const TestScreen({Key? key}) : super(key: key);
//
//   @override
//   _TestScreenState createState() => _TestScreenState();
// }
//
// class _TestScreenState extends State<TestScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Container(
//         child: GridView.builder(
//           shrinkWrap: true,
//           primary: false,
//           // scrollDirection: Axis.horizontal,
//           itemCount: 2,
//           itemBuilder: (BuildContext context, int index) {
//             return
//               Stack(
//               children: [
//                 Container(
//                   // decoration: BoxDecoration(
//                   //   border: Border.all(color: Colors.red)
//                   // ),
//                   //padding: EdgeInsets.all(4),
//                   // width: MediaQuery.of(context).size.width * 0.6,
//                   //   color: Colors.grey,
//                   child: Padding(
//                     padding: const EdgeInsets.all(2.0),
//                     child: Container(
//                       color: Colors.black,
//                     ),
//                   )
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.only(left: 4.0,right: 4.0,bottom: 4.0),
//                   child: Container(
//
//                     alignment: Alignment.bottomCenter,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[800]
//                       ),
//                       child: Row(
//
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.only(left: 8.0),
//                             child: Text("Abir Hasan ",style: TextStyle(fontSize: 14,color: Colors.white),),
//                           ),
//                           Spacer(),
//
//                           Padding(
//                             padding: const EdgeInsets.only(right: 8.0),
//                             child: Container(
//                               height: 30,
//                               child: Row(
//                                 children: [
//                                   GestureDetector(
//                                     onTap: (){},
//                                     child: Container(
//                                       padding: EdgeInsets.all(0),
//                                       decoration: BoxDecoration(
//                                         border: Border.all(color: Colors.grey),
//                                         // /  color: Colors.grey,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       height: 35,
//                                       width: 35,
//                                       child: Center(
//                                         child: Image.asset(
//                                           "assets/images/04.png",
//                                           height: 30,
//                                           width: 30,
//                                           fit: BoxFit.cover,
//                                         ),
//                                       ),
//                                     ),
//
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//
//
//
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             );
//             //   Stack(
//             //   children: [
//             //
//             //     Container(
//             //       child: Row(
//             //         children: [
//             //           Text("Abir",style: TextStyle(fontSize: 14,color: Colors.white),),
//             //
//             //           // Container(
//             //           //   height: 60,
//             //           //   child: Row(
//             //           //     children: [
//             //           //       GestureDetector(
//             //           //         onTap: (){},
//             //           //         child: Container(
//             //           //           padding: EdgeInsets.all(0),
//             //           //           decoration: BoxDecoration(
//             //           //             border: Border.all(color: Colors.grey),
//             //           //             // /  color: Colors.grey,
//             //           //             shape: BoxShape.circle,
//             //           //           ),
//             //           //           height: 35,
//             //           //           width: 35,
//             //           //           child: Center(
//             //           //             child: Image.asset(
//             //           //               "assets/images/03.png",
//             //           //               height: 30,
//             //           //               width: 30,
//             //           //               fit: BoxFit.cover,
//             //           //             ),
//             //           //           ),
//             //           //         ),
//             //           //
//             //           //       ),
//             //           //     ],
//             //           //   ),
//             //           // ),
//             //
//             //
//             //
//             //         ],
//             //       ),
//             //     ),
//             //   ],
//             // );
//           }, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,childAspectRatio: 4/4),
//         ),
//       ),
//     );
//   }
// }
