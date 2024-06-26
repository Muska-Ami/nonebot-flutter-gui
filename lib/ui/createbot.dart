import 'dart:convert';
import 'dart:io';

import 'package:NonebotGUI/darts/utils.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:NonebotGUI/ui/creatingbot.dart';
import 'package:http/http.dart' as http;

// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: CreateBot(),
//     );
//   }
// }

class CreateBot extends StatefulWidget {
  const CreateBot({super.key});

  @override
  State<CreateBot> createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<CreateBot> {
  final myController = TextEditingController();
  bool isVENV = true;
  bool isDep = true;
  String? _selectedFolderPath;

  Future<void> _pickFolder() async {
    String? folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath != null) {
      setState(() {
        _selectedFolderPath = folderPath.toString();
      });
    }
  }

//拉取适配器和驱动器列表
  @override
  void initState() {
    super.initState();
    _fetchAdapters();
  }

//驱动器，万年不更新一次的东西就不搞http请求了🤓
  Map<String, bool> drivers = {
    'None': false,
    'FastAPI': true,
    'Quart': false,
    'HTTPX': false,
    'websockets': false,
    'AIOHTTP': false,
  };

//适配器
  Map<String, bool> adapterMap = {};
  List adapterList = [];
  bool loadAdapter = true;
  Future<void> _fetchAdapters() async {
    final response =
        await http.get(Uri.parse('https://registry.nonebot.dev/adapters.json'));
    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      List<dynamic> adapters = json.decode(decodedBody);
      setState(() {
        adapterList = adapters;
        adapterMap = {for (var item in adapters) item['name']: false};
        loadAdapter = false;
      });
    } else {
      setState(() {
        loadAdapter = false;
      });
    }
  }

  void onDriversChanged(String option, bool value) {
    setState(() {
      drivers[option] = value;
    });
  }

  void onAdaptersChanged(String option, bool value) {
    setState(() {
      adapterMap[option] = value;
    });
  }

  String buildSelectedDriverOptions() {
    List<String> selectedOptions =
        drivers.keys.where((option) => drivers[option] == true).toList();
    String selectedDrivers = selectedOptions.join(',').toString();
    return selectedDrivers;
  }

  String buildSelectedAdapterOptions() {
    List<String> selectedOptions =
        adapterMap.keys.where((option) => adapterMap[option] == true).toList();
    List<String> selectedAdapters = selectedOptions.map((option) {
      String showText =
          '$option(${adapterList.firstWhere((adapter) => adapter['name'] == option)['module_name']})';
      return showText
          .replaceAll('adapters', 'adapter')
          .replaceAll('.', '-')
          .replaceAll('-v11', '.v11')
          .replaceAll('-v12', '.v12');
    }).toList();
    String selectedAdaptersString = selectedAdapters.join(', ');
    return selectedAdaptersString;
  }

  List<Widget> buildDriversCheckboxes() {
    return drivers.keys.map((driver) {
      return CheckboxListTile(
        title: Text(driver),
        activeColor: userColorMode() == 'light'
            ? const Color.fromRGBO(238, 109, 109, 1)
            : const Color.fromRGBO(127, 86, 151, 1),
        value: drivers[driver],
        onChanged: (bool? value) => onDriversChanged(driver, value!),
      );
    }).toList();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  void _toggleVenv(bool newValue) {
    setState(() {
      isVENV = newValue;
    });
  }

  void _toggleDep(bool newValue) {
    setState(() {
      isDep = newValue;
    });
  }

  String name = 'Nonebot';
  final List<String> template = ['bootstrap(初学者或用户)', 'simple(插件开发者)'];
  late String dropDownValue = template.first;
  final List<String> pluginDir = ['在[bot名称]/[bot名称]下', '在src文件夹下'];
  late String dropDownValuePluginDir = pluginDir.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "创建Bot",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: userColorMode() == 'light'
            ? const Color.fromRGBO(238, 109, 109, 1)
            : const Color.fromRGBO(127, 86, 151, 1),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              if (_selectedFolderPath.toString() != 'null') {
                createBotWriteConfig(
                  name,
                  _selectedFolderPath,
                  isVENV,
                  isDep,
                  buildSelectedDriverOptions(),
                  buildSelectedAdapterOptions(),
                  dropDownValue,
                  dropDownValuePluginDir,
                );
                createBotWriteConfigRequirement(
                  buildSelectedDriverOptions(),
                  buildSelectedAdapterOptions(),
                );
                createFolder(
                  _selectedFolderPath,
                  name,
                  dropDownValuePluginDir,
                );
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const CreatingBot();
                }));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('你还没有选择存放Bot的目录！'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            icon: const Icon(Icons.arrow_forward),
            color: Colors.white,
            tooltip: "下一步",
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            //bot名称
            children: <Widget>[
              TextField(
                controller: myController,
                decoration: const InputDecoration(
                  hintText: "bot名称，不填则默认为Nonebot",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromRGBO(238, 109, 109, 1),
                      width: 5.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() => name = value);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  const Expanded(
                      child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '选择模板',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  )),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: DropdownButton<String>(
                        value: dropDownValue,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        elevation: 16,
                        onChanged: (String? value) {
                          setState(() => dropDownValue = value!);
                        },
                        items: template
                            .map<DropdownMenuItem<String>>(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              Visibility(
                visible: dropDownValue == template[1],
                child: Row(
                  children: <Widget>[
                    const Expanded(
                        child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '选择插件存放位置',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: DropdownButton<String>(
                          value: dropDownValuePluginDir,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          elevation: 16,
                          onChanged: (String? value) {
                            setState(() {
                              dropDownValuePluginDir = value!;
                            });
                          },
                          items: pluginDir
                              .map<DropdownMenuItem<String>>(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 12,
              ),
              //bot目录
              Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '存放bot的目录[$_selectedFolderPath]',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: _pickFolder,
                        tooltip: "选择bot存放路径",
                        icon: const Icon(Icons.folder),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 10,
              ),

              Row(
                children: <Widget>[
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("是否开启虚拟环境"),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: isVENV,
                        onChanged: _toggleVenv,
                        activeColor: userColorMode() == 'light'
                            ? const Color.fromRGBO(238, 109, 109, 1)
                            : const Color.fromRGBO(127, 86, 151, 1),
                        focusColor: Colors.black,
                        inactiveTrackColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("是否安装依赖"),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Switch(
                        value: isDep,
                        onChanged: _toggleDep,
                        activeColor: userColorMode() == 'light'
                            ? const Color.fromRGBO(238, 109, 109, 1)
                            : const Color.fromRGBO(127, 86, 151, 1),
                        focusColor: Colors.black,
                        inactiveTrackColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(
                height: 20,
                thickness: 2,
                indent: 20,
                endIndent: 20,
                color: Colors.grey,
              ),
              const Center(
                child: Text("选择驱动器"),
              ),
              const SizedBox(
                height: 3,
              ),
              Column(children: buildDriversCheckboxes()),

              const Divider(
                height: 20,
                thickness: 2,
                indent: 20,
                endIndent: 20,
                color: Colors.grey,
              ),
              const Center(
                child: Text("选择适配器"),
              ),
              const SizedBox(
                height: 3,
              ),
              Column(
                children: [
                  if (loadAdapter)
                    Center(
                      child: CircularProgressIndicator(
                        color: userColorMode() == 'light'
                            ? const Color.fromRGBO(238, 109, 109, 1)
                            : const Color.fromRGBO(127, 86, 151, 1),
                      ),
                    )
                  else
                    ListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: adapterList.map((adapter) {
                        String name = adapter['name'];
                        //屎山，别骂了别骂了😭
                        // 还好
                        String moduleName = adapter['module_name']
                            .replaceAll('adapters', 'adapter')
                            .replaceAll('.', '-')
                            .replaceAll('-v11', '.v11')
                            .replaceAll('-v12', '.v12');
                        String showText = '$name($moduleName)';
                        return CheckboxListTile(
                          activeColor: userColorMode() == 'light'
                              ? const Color.fromRGBO(238, 109, 109, 1)
                              : const Color.fromRGBO(127, 86, 151, 1),
                          title: Text(showText),
                          value: adapterMap[name],
                          onChanged: (bool? value) =>
                              onAdaptersChanged(name, value!),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
