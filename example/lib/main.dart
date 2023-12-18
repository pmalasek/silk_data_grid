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
              locale: const Locale("CS_cz"),
              // locale: const Locale("en_GB"),
              // locale: const Locale("en_US"),
              // locale: const Locale("zh_HK"),

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
              columns: SilkGridColumns(
                items: [
                  SilkGridIntField(label: "id", field: "recid", size: 60, hidden: false),
                  SilkGridStringField(label: "SPZ", field: "spz", size: 100),
                  SilkGridStringField(label: "VIN", field: "vin", size: 150),
                  SilkGridMoneyField(label: "Cena", field: "price", size: 120),
                  SilkGridMoneyField(label: "Cena DPH", field: "price_vat", size: 120),
                  SilkGridDoubleField(label: "Hod. práce", field: "cnt_work", precision: 1, size: 120),
                  SilkGridStringField(label: "Značka", field: "brand", minSize: 100, sortable: true),
                  SilkGridStringField(label: "Barva", field: "color", minSize: 100),
                  SilkGridDateTimeField(label: "Datum pořízení", field: "date_buy", size: 180),
                  SilkGridStringField(label: "Vlastník", field: "company_name", minSize: 200),
                  SilkGridStringField(label: "Nájemce", field: "najem_firma", minSize: 200),
                  SilkGridStringField(label: "Uživatel", field: "person_name", minSize: 200),
                  SilkGridStringField(label: "Palivo", field: "fuel", size: 100),
                  SilkGridIntField(label: "Max hmotn.", field: "max_load", size: 80),
                  SilkGridStringField(
                    label: "Stav",
                    field: "state",
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
                  // ),
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
