import 'package:flutter/material.dart';

class ActionSheet<T> {
  final List<ActionSheetItem> children;
  final bool showCancel;
  final BuildContext context;
  Function onClosing;
  final Function(T) onClickItem;

  ActionSheet(
      {@required this.context,
      @required this.children,
      this.showCancel = false,
      this.onClosing,
      @required this.onClickItem});

  void show() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          
          List<Widget> _children = children.map((item) {
            return Container(
                width: MediaQuery.of(context).size.width,
                child: FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.onClickItem(item.value);
                  },
                  child: Text(
                    item.label,
                    style: new TextStyle(
                color: item.label=="橘子" ? Color(0xFF323232) : const Color(0xFF3676F2), //文字颜色
              ),
                    ),
                ));
          }).toList();

          if (showCancel) {
            _children.add(Container(
              child: null,
              color: Colors.black12,
              padding: EdgeInsets.only(top: 8.0),
            ));
            _children.add(Container(
                width: MediaQuery.of(context).size.width,
                child: FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('取消'),
                )));
          }

          return BottomSheet(
            onClosing: () {
              onClosing();
            },
            builder: (ctx) {
              return SingleChildScrollView(
                  child: Column(
                children: _children,
                mainAxisSize: MainAxisSize.min,
              ));
            },
          );
        });
  }
}

class ActionSheetItem {
  final String label;
  final value;
  ActionSheetItem({@required this.label, @required this.value});
}