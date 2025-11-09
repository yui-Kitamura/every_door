import 'package:every_door/constants.dart';
import 'package:every_door/fields/address_form.dart';
import 'package:every_door/generated/l10n/app_localizations.dart' show AppLocalizations;
import 'package:every_door/providers/editor_settings.dart';
import 'package:every_door/widgets/radio_field.dart';
import 'package:every_door/providers/osm_data.dart';
import 'package:flutter/material.dart';
import 'package:every_door/models/address_blockbased.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressFormBlockBasedField extends AddressFormField {
  
  const AddressFormBlockBasedField(super.field, super.element);

  @override
  ConsumerState<AddressFormBlockBasedField> createState() => _AddressFormFieldBlockBasedState();
}

class _AddressFormFieldBlockBasedState extends ConsumerState<AddressFormBlockBasedField> {
  late final TextEditingController _neighController;
  late final TextEditingController _blockController;
  late final TextEditingController _houseController;

  List<String> nearestNeighbourhoods = [];

  @override
  void initState() {
    super.initState();
    final address = BlockBasedAddress.fromTags(widget.element.getFullTags());
    _neighController = TextEditingController(text: address.neighbourhood);
    _blockController = TextEditingController(text: address.blockNumber);
    _houseController = TextEditingController(text: address.housenumber);
    _updateNearbyAddressHints();
  }

  @override
  void dispose() {
    _neighController.dispose();
    _blockController.dispose();
    _houseController.dispose();

    super.dispose();
  }

  List<String> _filterDuplicates(Iterable<String?> source) {
    final values = <String>{};
    final result = source.whereType<String>().toList();
    result.retainWhere((element) => values.add(element));
    return result;
  }

  Future<void> _updateNearbyAddressHints() async {
    final provider = ref.read(osmDataProvider);
    final addrs = await provider.getBlockBasedAddressesAround(
      widget.element.location,
      limit: 30,
    );
    setState(() {
      nearestNeighbourhoods = _filterDuplicates(
        addrs.map((e) => e.neighbourhood ?? e.suburb ?? e.city),
      );
    });
  }

  String? get house {
    final value = _houseController.text.trim();
    return value.isEmpty ? null : value;
  }

  String? get neighbourhoodValue {
    final value = _neighController.text.trim();
    return value.isEmpty ? null : value;
  }

  String? neighbourhood;

  void notifyOnChange() {
    final block = _blockController.text.trim();
    final neigh = neighbourhoodValue ?? neighbourhood;
    final address = BlockBasedAddress(
      housenumber: house,
      blockNumber: block.isEmpty ? null : block,
      neighbourhood: (neigh != null && neigh.isNotEmpty) ? neigh : null,
    );
    address.forceTags(widget.element);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final numericKeyboardType = ref.watch(editorSettingsProvider).keyboardType;

    // Order: Neighbourhood -> Block -> House
    return Table(
      columnWidths: const { 0: FixedColumnWidth(100.0) },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        if (nearestNeighbourhoods.isNotEmpty)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Text('Neighbourhood', style: kFieldTextStyle),
              ),
              RadioField(
                options: nearestNeighbourhoods,
                value: neighbourhood,
                onChange: (value) {
                  setState(() {
                    neighbourhood = value;
                    if (value != null) _neighController.text = value;
                  });
                  notifyOnChange();
                },
              ),
            ],
          ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text('Neighbourhood', style: kFieldTextStyle),
            ),
            TextFormField(
              controller: _neighController,
              style: kFieldTextStyle,
              onChanged: (value) {
                setState(() {
                  neighbourhood = value.trim().isEmpty ? null : value.trim();
                });
                notifyOnChange();
              },
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                loc.addressBlock,
                style: kFieldTextStyle.copyWith(
                  color: _houseController.text.trim().isNotEmpty && _blockController.text.trim().isEmpty
                      ? Colors.red
                      : null,
                ),
              ),
            ),
            TextFormField(
              controller: _blockController,
              keyboardType: numericKeyboardType,
              style: kFieldTextStyle,
              onChanged: (value) {
                notifyOnChange();
              },
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                loc.addressHouseNumber,
                style: kFieldTextStyle.copyWith(
                  color: _houseController.text.trim().isEmpty && _blockController.text.trim().isNotEmpty
                      ? Colors.red
                      : null,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _houseController,
                    keyboardType: TextInputType.visiblePassword,
                    autofocus: widget.field.autoFocus,
                    style: kFieldTextStyle,
                    decoration: const InputDecoration(hintText: '1, 89, 154A, ...'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? loc.addressHouseNotEmpty
                        : null,
                    onChanged: (value) {
                      notifyOnChange();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
