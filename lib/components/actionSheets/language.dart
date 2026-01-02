import 'package:calorie/network/api.dart';
import 'package:calorie/store/store.dart';
import 'package:calorie/store/user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

List langList = [{'label':'English','value':'en_US'},{'label':'中文','value':'zh_CN'}];
class LanguageSheet extends StatefulWidget {
  const LanguageSheet({super.key});
  @override
  State<LanguageSheet> createState() => _LanguageSheetState();
}

class _LanguageSheetState extends State<LanguageSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: Colors.white),
      height: 240,
      padding: const EdgeInsets.all(20),
      child:  Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 193, 193, 193),
              borderRadius: BorderRadius.circular(10)
            ),
            width: 40,
            height: 5,
          ),
          const SizedBox(height: 35,),
          ...langList.map((item)=>
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: const Color.fromARGB(255, 252, 247, 255),
              minimumSize: const Size(double.infinity, 50),
              shadowColor: const Color.fromRGBO(0, 255, 255, 255),
            ),
            onPressed: ()async{
              await userModify({
                'lang':item['value'],
              });
              
              await UserInfo().getUserInfo();
              Controller.c.lang(item['value']);
              Get.back();
            },
            child: Text(item['label'], style: const TextStyle(color: Colors.black, fontSize: 16)),
          ),
          )
          ),
          
          const SizedBox(height: 20,),

        ],
      ),
    );
  }
}
