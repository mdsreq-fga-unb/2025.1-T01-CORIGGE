import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';

class DropdownSearchCustom<T> extends StatelessWidget {
  final String hintText;
  final IconData prefixIcon;
  final List<T> items;
  final T? selectedItem;
  final String Function(T) itemAsString;
  final void Function(T?) onChanged;
  final bool Function(T, T)? compareFn;

  const DropdownSearchCustom({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    required this.items,
    required this.selectedItem,
    required this.itemAsString,
    required this.onChanged,
    this.compareFn,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<T>(
      decoratorProps: DropDownDecoratorProps(
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(prefixIcon, color: Colors.brown[800]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.brown[800]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      popupProps: PopupProps.menu(
        showSearchBox: true,
        containerBuilder: (context, popupWidget) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
            ),
            child: popupWidget,
          );
        },
        menuProps: MenuProps(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Pesquisar $hintText",
            prefixIcon: Icon(Icons.search, color: Colors.brown[800]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.brown[800]!),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ),
      items: (c, v) => items,
      selectedItem: selectedItem,
      itemAsString: itemAsString,
      onChanged: onChanged,
      compareFn: compareFn,
    );
  }
}
