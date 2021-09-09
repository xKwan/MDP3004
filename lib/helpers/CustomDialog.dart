import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mdp3004/helpers/Util.dart';

class CustomDialog {
  static Future<Map<String, int>> showDialog(BuildContext context) {
    TextEditingController _columnController = TextEditingController();
    TextEditingController _rowController = TextEditingController();
    Map<String, int> gridVal = {};
    bool _validate = false;

    showGeneralDialog(
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 700),
      context: context,
      pageBuilder: (_, __, ___) {
        return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 300,
              child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Card(
                      shadowColor: Colors.transparent,
                      child: Column(
                        children: <Widget>[
                          TextField(
                            maxLength: 2,
                            controller: _columnController,
                            decoration: InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black
                                  )
                              ),
                              hintText: "10",
                              labelText: "Column",
                              labelStyle: TextStyle(
                                  color: Colors.black
                              ),
                              hintStyle: TextStyle(
                                  color: Colors.grey
                              ),
                            ),
                          ),
                          TextField(
                            maxLength: 2,
                            controller: _rowController,
                            decoration: InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black
                                  ),
                              ),
                              hintText: "15",
                              labelText: "Row",
                              labelStyle: TextStyle(
                                  color: Colors.black
                              ),
                              hintStyle: TextStyle(
                                  color: Colors.grey
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15.0),
                            child: Material(
                              elevation: 5,
                              borderRadius: BorderRadius.circular(15),
                              color: Colors.green,
                              child: MaterialButton(
                                padding: EdgeInsets.all(15.0),
                                child: Text('OK',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  // fontSize: ,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                                onPressed: () async {
                                  print(_rowController.text);
                                  print(_columnController.text);
                                  if(_rowController.text!.isNotEmpty && _columnController.text!.isNotEmpty){
                                    try {
                                      if(_rowController.text=="0" || _columnController.text=="0")
                                        throw Exception("Row and column cannot be 0");
                                      else if(int.parse(_rowController.text)>20 || int.parse(_columnController.text)>20)
                                        throw Exception("Row and column cannot be more than 20");

                                      gridVal.addAll({"row":int.parse(_rowController.text), "column":int.parse(_columnController.text)});
                                      Navigator.of(context).pop();

                                    } catch (e) {
                                      Utils.showSnackBar(
                                        context,
                                        text: 'Please enter a number between 1 to 20.',
                                        color: Colors.white70.withOpacity(0.5),
                                      );                                    }
                                  } else {
                                    Utils.showSnackBar(
                                      context,
                                      text: 'Field cannot be empty.',
                                      color: Colors.white70.withOpacity(0.5),
                                    );
                                  }

                                },
                              ),
                            ),
                          )

                        ],
                      ),
                    ),
                  )
              ),
              margin: EdgeInsets.only(bottom: 50, left: 12, right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
            ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(anim),
          child: child,
        );
      },
    );

    return Future.value(gridVal);

  }
}
