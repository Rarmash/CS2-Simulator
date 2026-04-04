import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/agent_collection_content_dto.dart';
import '../models/agent_dto.dart';
import '../models/container_content_dto.dart';
import '../models/container_dto.dart';
import '../models/charm_content_dto.dart';
import '../models/charm_dto.dart';
import '../models/graffiti_content_dto.dart';
import '../models/graffiti_dto.dart';
import '../models/music_kit_content_dto.dart';
import '../models/music_kit_dto.dart';
import '../models/music_kit_group_dto.dart';
import '../models/operation_collection_content_dto.dart';
import '../models/patch_content_dto.dart';
import '../models/patch_dto.dart';
import '../models/pin_content_dto.dart';
import '../models/pin_dto.dart';
import '../models/reward_collection_content_dto.dart';
import '../models/skin_dto.dart';
import '../models/sticker_content_dto.dart';
import '../models/sticker_dto.dart';

part 'local_data_repository_loaders.dart';
part 'local_data_repository_queries.dart';
part 'local_data_repository_sorting.dart';

class LocalDataRepository
    with _LocalDataRepositoryLoaders, _LocalDataRepositoryQueries {}
