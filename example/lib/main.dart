import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:silk_data_grid/silk_data_grid.dart';
// import 'package:http/http.dart';

//
// flutter build web --base-href "/"; scp -r build/web/* 172.24.0.14:/home/devel/www/
//
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final bool _useMat3 = true;
  final Color _color = const Color.fromARGB(255, 42, 40, 77);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _color,
          brightness: Brightness.light,
        ),
        useMaterial3: _useMat3,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _color,
          brightness: Brightness.dark,
        ),
        useMaterial3: _useMat3,
      ),
      themeMode: ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("SilkGridView"),
        ),
        body: const Padding(
          padding: EdgeInsets.all(18.0),
          // child: SilkGridViewLoaderPartial(),
          child: SilkGridViewLoader(),
          // child: TableExample(),
        ),
      ),
    );
  }
}

class SilkGridViewLoader extends StatelessWidget {
  const SilkGridViewLoader({super.key});

  Future<List<dynamic>> loadData() async {
    String jsonString = await rootBundle.loadString('assets/json/data.json');
    return Future.delayed(const Duration(milliseconds: 50), () {
      var data = jsonDecode(jsonString);
      return data['records'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: loadData(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            //return SilkExtendeGridView(
            return SilkGridView(
              multiselect: true,
              actions: [
                IconButton(
                  tooltip: "My tooltip",
                  icon: const Icon(
                    Icons.settings,
                  ),
                  onPressed: () {
                    // do something
                  },
                )
              ],
              onBtnTap: (row, col, record, details) {
                // print(record);
              },
              onChangeRow: (row, col, record) {
                // print("Change $row, $col");
              },
              onGetRowColor: (row, record) {
                if (record['state'] == 'prodáno') return Colors.red.shade100.withOpacity(0.1);
                if (record['state'] == 'jen servis') return Colors.blue.shade100.withOpacity(0.2);
                return null;
              },
              // borderColor: Colors.grey.shade300,
              // headerColor: Colors.amber,
              // headerTextColor: Colors.red,
              // textColor: Colors.black,
              // selectedRowColor: Colors.blue,
              // selectedRowTextColor: Colors.greenAccent.shade700,
              // selectedColColor: Colors.red,
              // selectedColTextColor: Colors.yellow,
              // toolbarColor: Colors.white60,
              // toolbarIconColor: Colors.red,
              columns: SilkGridColumns(
                items: [
                  SilkGridField(label: "id", field: "recid", fieldType: SilkFieldType.int, size: 60, hidden: true),
                  SilkGridField(label: "SPZ", field: "spz", fieldType: SilkFieldType.string, size: 100),
                  SilkGridField(label: "VIN", field: "vin", fieldType: SilkFieldType.string, size: 150),
                  SilkGridField(
                    label: "Značka",
                    field: "brand",
                    fieldType: SilkFieldType.string,
                    minSize: 100,
                    sortable: true,
                    formatText: (int row, int col, SilkGridColumns columns, record) {
                      return "${columns[col].field} -  ${record['brand']} ${record['model']}";
                    },
                  ),
                  SilkGridField(
                    label: "Barva",
                    field: "color",
                    fieldType: SilkFieldType.string,
                    minSize: 100,
                    formatText: (row, col, columns, record) {
                      return "${record['color'].toString()} - ${record['color']}";
                    },
                  ),
                  SilkGridField(label: "Datum pořízení", field: "date_buy", fieldType: SilkFieldType.date, size: 100),
                  SilkGridField(label: "Vlastník", field: "company_name", fieldType: SilkFieldType.string, minSize: 100),
                  SilkGridField(label: "Nájemce", field: "najem_firma", fieldType: SilkFieldType.string, minSize: 100),
                  SilkGridField(label: "Uživatel", field: "person_name", fieldType: SilkFieldType.string, minSize: 100),
                  SilkGridField(label: "Palivo", field: "fuel", fieldType: SilkFieldType.string, size: 100),
                  SilkGridField(label: "Max hmotn.", field: "max_load", fieldType: SilkFieldType.int, size: 80),
                  SilkGridField(
                    label: "Stav",
                    field: "state",
                    fieldType: SilkFieldType.string,
                    size: 100,
                    cellBuilder: (row, col, columns, record, textStyle) {
                      return Text(
                        record["state"].toString(),
                        style: textStyle.copyWith(
                          decoration: record["state"] == 'prodáno' ? TextDecoration.lineThrough : null,
                          color: record["state"] == 'prodáno' ? Colors.red : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
              rows: snapshot.data,
              footerRows: SilkGridFooter(
                rows: [
                  SilkGridFooterRow(
                    values: [
                      SilkGridFooterTextRowValue(value: "Toto je delší CUSTOM text"),
                      SilkGridFooterFieldRowValue(field: 'fuel', value: 1234.2),
                      SilkGridFooterFieldRowValue(field: 'date_buy', value: 9876.5),
                      SilkGridFooterFieldRowValue(field: 'company_name', value: 9876.5),
                    ],
                  ),
                  SilkGridFooterRow(
                    values: [
                      SilkGridFooterFieldRowValue(field: 'fuel', value: 9876.5),
                      SilkGridFooterTextRowValue(value: "Toto je text ZA"),
                    ],
                  ),
                  SilkGridFooterRow(
                    values: [
                      SilkGridFooterFieldRowValue(field: 'vin', value: 9876.5),
                      SilkGridFooterFieldRowValue(field: 'fuel', value: 9876.5),
                      SilkGridFooterTextRowValue(value: "Toto je text ZA"),
                    ],
                  ),
                  SilkGridFooterRow(
                    values: [
                      SilkGridFooterTextRowValue(value: "První text"),
                      SilkGridFooterTextRowValue(value: "Druhý text"),
                      SilkGridFooterTextRowValue(value: "Třetí text"),
                      SilkGridFooterFieldRowValue(field: 'person_name', value: 15.2),
                    ],
                  ),
                ],
              ),
            );
          default:
            return const Center(
              child: CircularProgressIndicator(),
            );
        }
      },
    );
    //TableView.builder();
  }
}
