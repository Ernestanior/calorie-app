// import 'dart:html';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


class AboutUs extends StatefulWidget {
  const AboutUs({super.key});
  @override
  State<AboutUs> createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('About Us',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          const SizedBox(height: 100),
          const Center(
            child: Column(
              children: [
                SizedBox(height: 10),
                Text(
                  'Vita AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
               
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                _buildListItem('CURRENT_VERSION'.tr,(){}, version: '1.2.1'),
                _buildListItem('PRIVACY_POLICY'.tr, (){
                  Navigator.pushNamed(context, '/privacy');
                }, icon:Icons.chevron_right),
                _buildListItem('TERMS_AND_CONDITIONS'.tr, (){
                  Navigator.pushNamed(context, '/service');
                },icon: Icons.chevron_right),
              ],
            ),
          ),
          const Spacer(),
          
        ],
        ),
    );
  }
}

Widget _buildListItem(String title,  GestureTapCallback onTap, {String? version, IconData? icon}) {
    return GestureDetector(
      onTap: () {
        
      },
      child:  ListTile(
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          version != null?  Text(version, style: const TextStyle(color: Colors.grey)):Icon(icon, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    ),
    ) ;
  }