import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MailButton extends StatelessWidget {
  const MailButton({super.key});

  // 固定收件人
  final String email = "ern@xyvnai.com";

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      throw "Cannnot open mail";
    }
  }

  @override
  Widget build(BuildContext context) {
    return 
     Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color.fromARGB(31, 111, 117, 162),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            IconButton(
      icon: const Icon(Icons.email, color: Colors.black,size: 36,),
      onPressed: _sendEmail,
    ),
    const Text('ern@xyvnai.com',style: TextStyle(fontSize: 16),)
          ],
        ))
    
     
     ;
  }
}
