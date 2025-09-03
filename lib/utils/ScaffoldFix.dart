
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/* Later android versions made it so that the navigation bar draws on top of the app.
* This custom scaffold implementation fixes that until flutter fixes it on their end  */

class ScaffoldFix extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final PreferredSizeWidget? appBar;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Drawer? drawer;
  final Drawer? endDrawer;
  final bool extendBody;

  const ScaffoldFix({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.extendBody = false,
  });

  @override
  Widget build(BuildContext context) {
    // final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      endDrawer: endDrawer,
      body: bottomNavigationBar == null
          ? SafeArea(
        child: body,
      )
          : body,
      bottomNavigationBar: bottomNavigationBar != null
          ? SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 0),
          child: bottomNavigationBar,
        ),
      )
          : null,
    );
  }
}