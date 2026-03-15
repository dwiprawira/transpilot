class TransmissionFields {
  static const list = <String>[
    'id',
    'hashString',
    'name',
    'status',
    'percentDone',
    'metadataPercentComplete',
    'totalSize',
    'sizeWhenDone',
    'rateDownload',
    'rateUpload',
    'eta',
    'uploadRatio',
    'peersConnected',
    'peersSendingToUs',
    'peersGettingFromUs',
    'downloadDir',
    'trackers',
    'trackerStats',
    'error',
    'errorString',
    'addedDate',
    'doneDate',
    'activityDate',
    'bandwidthPriority',
    'queuePosition',
    'isFinished',
    'downloadedEver',
    'uploadedEver',
    'secondsDownloading',
    'secondsSeeding',
  ];

  static const detail = <String>[
    ...list,
    'comment',
    'creator',
    'dateCreated',
    'desiredAvailable',
    'downloadLimit',
    'downloadLimited',
    'haveUnchecked',
    'haveValid',
    'honorsSessionLimits',
    'leftUntilDone',
    'magnetLink',
    'pieceCount',
    'pieceSize',
    'primary-mime-type',
    'trackerList',
    'uploadLimit',
    'uploadLimited',
  ];

  static const files = <String>['id', 'files', 'fileStats'];

  static const peers = <String>['id', 'peers'];
}
