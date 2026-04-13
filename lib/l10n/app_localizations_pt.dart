// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'RED GRID LINK';

  @override
  String get tabMap => 'MAPA';

  @override
  String get tabGrid => 'GRADE';

  @override
  String get tabLink => 'LINK';

  @override
  String get tabTools => 'FERRAM';

  @override
  String get tabSettings => 'CONFIG';

  @override
  String get waitingForGps => 'Aguardando sinal GPS...';

  @override
  String get connected => 'Conectado';

  @override
  String get disconnected => 'Desconectado';

  @override
  String get reconnecting => 'Reconectando';

  @override
  String get scanning => 'Buscando';

  @override
  String get expedition => 'EXPEDICAO';

  @override
  String get ultraExpedition => 'ULTRA EXP';

  @override
  String get active => 'ATIVO';

  @override
  String get offlineMaps => 'MAPAS OFFLINE';

  @override
  String get downloadCurrentView => 'BAIXAR VISTA ATUAL';

  @override
  String get download => 'BAIXAR';

  @override
  String get downloadedRegions => 'REGIOES BAIXADAS';

  @override
  String get noOfflineRegions => 'Nenhuma regiao offline baixada.';

  @override
  String get createSession => 'CRIAR SESSAO';

  @override
  String get joinSession => 'ENTRAR NA SESSAO';

  @override
  String get leaveSession => 'SAIR DA SESSAO';

  @override
  String get close => 'FECHAR';

  @override
  String get cancel => 'CANCELAR';

  @override
  String get confirm => 'CONFIRMAR';

  @override
  String get delete => 'EXCLUIR';

  @override
  String get save => 'SALVAR';

  @override
  String get settings => 'CONFIGURACOES';

  @override
  String get theme => 'TEMA';

  @override
  String get mode => 'MODO';

  @override
  String get about => 'SOBRE';

  @override
  String get tools => 'FERRAMENTAS';

  @override
  String get deadReckoning => 'Navegacao Estimada';

  @override
  String get resection => 'Resseccao de Dois Pontos';

  @override
  String get paceCount => 'Contagem de Passos';

  @override
  String get backAzimuth => 'Azimute Reverso';

  @override
  String get coordinateConverter => 'Conversor de Coordenadas';

  @override
  String get rangeEstimation => 'Estimativa de Distancia';

  @override
  String get slopeCalculator => 'Calculadora de Inclinacao';

  @override
  String get etaSpeed => 'ETA / Velocidade';

  @override
  String get declination => 'Declinacao';

  @override
  String get celestialNav => 'Navegacao Celeste';

  @override
  String get mgrsReference => 'Referencia MGRS';

  @override
  String get teamRoster => 'EQUIPE';

  @override
  String get roleLead => 'Líder';

  @override
  String get roleScout => 'Batedor';

  @override
  String get roleMedic => 'Médico';

  @override
  String get roleComms => 'Comms';

  @override
  String get roleCustom => 'Personalizado';

  @override
  String get changeRole => 'MUDAR FUNÇÃO';

  @override
  String get promoteToLead => 'PROMOVER A LÍDER';

  @override
  String get saveToMyWaypoints => 'SALVAR NOS MEUS PONTOS';

  @override
  String get shareWithTeam => 'COMPARTILHAR COM EQUIPE';

  @override
  String get setBoundary => 'DEFINIR LIMITE';

  @override
  String get boundaryAlert => 'ALERTA DE LIMITE';

  @override
  String get youLeftBoundary => 'Você saiu do limite da equipe';

  @override
  String peerLeftBoundary(String callsign) {
    return '$callsign saiu do limite';
  }

  @override
  String get voiceCallouts => 'Chamadas de voz';

  @override
  String get voiceCalloutsSubtitle => 'Atualizações de posição NATO';

  @override
  String get exportSession => 'EXPORTAR SESSÃO';

  @override
  String get importSession => 'IMPORTAR SESSÃO';

  @override
  String get sessionHistory => 'HISTÓRICO DE SESSÕES';

  @override
  String get deleteAnnotation => 'Excluir anotação?';

  @override
  String get waypointName => 'Nome do ponto';

  @override
  String get undo => 'DESFAZER';

  @override
  String get done => 'CONCLUÍDO';
}
