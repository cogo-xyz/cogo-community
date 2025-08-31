library cogo_chat_sdk_flutter;

export 'endpoints/capabilities.dart';
export 'endpoints/design_generate.dart';
export 'endpoints/figma_context.dart';
export 'endpoints/compat/variables_derive.dart';
export 'endpoints/compat/symbols_map.dart';
export 'endpoints/bdd.dart';
export 'endpoints/actionflow.dart';
export 'endpoints/data_action.dart';
export 'endpoints/attachments.dart';
export 'models/envelope.dart';
export 'models/capabilities.dart';
export 'models/sse_events.dart';
export 'models/artifacts.dart';
export 'models/ide_hints.dart';
export 'models/editor_context.dart';
export 'utils/http.dart';
export 'utils/sse.dart';
export 'utils/artifacts.dart';
export 'utils/idempotency.dart';
export 'utils/supabase.dart';
export 'utils/sse_typed.dart';
export 'utils/editor.dart';
export 'utils/artifacts_supabase.dart';
export 'utils/errors.dart';
export 'endpoints/intent.dart';
export 'endpoints/trace_status.dart';

import 'endpoints/capabilities.dart';
import 'endpoints/design_generate.dart';
import 'endpoints/figma_context.dart';
import 'endpoints/compat/symbols_map.dart';
import 'endpoints/compat/variables_derive.dart';
import 'endpoints/attachments.dart';
import 'endpoints/bdd.dart';
import 'endpoints/actionflow.dart';
import 'endpoints/intent.dart';
import 'endpoints/trace_status.dart';

class CogoChatClient {
  final String edgeBase;
  final String anonKey;
  final String? supabaseUrl; // optional, for Realtime

  CogoChatClient({required this.edgeBase, required this.anonKey, this.supabaseUrl});

  CogoCapabilitiesEndpoint get capabilities =>
      CogoCapabilitiesEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoDesignGenerateEndpoint get designGenerate =>
      CogoDesignGenerateEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoFigmaContextEndpoint get figmaContext =>
      CogoFigmaContextEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoSymbolsMapEndpoint get symbolsMap =>
      CogoSymbolsMapEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoVariablesDeriveEndpoint get variablesDerive =>
      CogoVariablesDeriveEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoAttachmentsEndpoint get attachments =>
      CogoAttachmentsEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoBddEndpoint get bdd =>
      CogoBddEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoActionflowEndpoint get actionflow =>
      CogoActionflowEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoIntentEndpoint get intent => CogoIntentEndpoint(edgeBase: edgeBase, anonKey: anonKey);

  CogoTraceStatusEndpoint get traceStatus => CogoTraceStatusEndpoint(edgeBase: edgeBase, anonKey: anonKey);
}
