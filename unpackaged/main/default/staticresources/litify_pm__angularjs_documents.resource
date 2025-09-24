(function(jQuery, litify) {

  document.addEventListener( "contextmenu", function(e) {
    console.log(e);
    e.preventDefault();
  });

  const documentsApp = angular.module('documentsApp', ['ngProgress', 'ang-drag-drop', 'ngTable', 'ngFileUpload', 'litify', 'InlineEdit', 'angucomplete-alt']);

  documentsApp.factory('chatterFilesProvider', ['$q', '$http', 'Upload', function($q, $http, Upload) {
    function writeFile(path, file, progressCb, litifyDoc) {
      var deferred = $q.defer();
      _validateStorageLimits(file).then(
        function () {
          var filename =  _.last(path.split('/'), 1)[0];
          Upload.base64DataUrl(file).then(function(dataUrl) {
            var base64Data = dataUrl.substring(dataUrl.indexOf(',') + 1);
            var data = {
              'VersionData': base64Data,
              'Title': filename,
              'PathOnClient': filename
            };
            if (litifyDoc) {
              const contentDocumentId = litifyDoc.litify_doc.litify_pm__ProviderPath__c;
              if (contentDocumentId) {
                data.ContentDocumentId = contentDocumentId;
                data.ReasonForChange = "New Version uploaded via Litify Docs";
              }
            }
            $http({
              method: 'POST',
              url: '/services/data/v52.0/sobjects/ContentVersion',
              headers: {
                'Authorization': 'Bearer ' + window.sforce.connection.sessionId,
                'Content-Type': 'application/json'
              },
              uploadEventHandlers: {
                progress: progressCb
              },
              data: data
            }).then(function(result) {
              var contentVersionId = result.data.id;
              sforce.connection.query("SELECT ContentDocumentId FROM ContentVersion WHERE Id = '" + contentVersionId + "'", {
                onSuccess: function(result) {
                  var records = result.getArray('records');
                  deferred.resolve(records[0].ContentDocumentId);
                },
                onFailure: function(error) {
                  deferred.reject(error);
                }
              });
            }, deferred.reject);
          }, deferred.reject);
        }, deferred.reject);

      return deferred.promise;
    }

    function deleteFile(fileIds) {
      var deferred = $q.defer();

      fileIds = _.isArray(fileIds) ? fileIds : [fileIds];

      sforce.connection.deleteIds(fileIds, {
        onSuccess: deferred.resolve,
        onFailure: deferred.reject
      });

      return deferred.promise;
    }

    function readFileHttpCall(contentDocumentId, versionNumber) {
      var deferred = $q.defer();

      var url = '/services/data/v39.0/connect/files/' + contentDocumentId;
      if (versionNumber) {
        url += '?versionNumber=' + versionNumber;
      }
      $http({
        method: 'GET',
        url: url,
        headers: {
          'Authorization': 'Bearer ' + window.sforce.connection.sessionId
        }
      }).then(function(response) {
        var documentInfo = response.data;
        deferred.resolve({
          contentDocumentProviderPath: documentInfo.id,
          downloadUrl: documentInfo.downloadUrl,
          fileName: documentInfo.fileName
        });
      }, deferred.reject);
      return deferred.promise;
    }

    function readFile(fileIds) {
      var deferred = $q.defer();
      var promises = _.map(fileIds, readFileHttpCall);
      $q.all(promises).then(deferred.resolve, deferred.reject);
      return deferred.promise;
    }

    function readVersion(versionId) {
      var deferred = $q.defer();

      var query = "SELECT Title, ContentDocumentId, VersionNumber FROM ContentVersion WHERE Id = '" + versionId + "'";
      sforce.connection.query(query, {
        onSuccess: function(data) {
          var it = new sforce.QueryResultIterator(data);
          while(it.hasNext()) {
            var record = it.next();
            readFileHttpCall(record.ContentDocumentId, record.VersionNumber).then(deferred.resolve, deferred.reject);
          }
        },
        onFailure: deferred.reject
      });

      return deferred.promise;
    }

    function readPreview(fileIds) {
      fileIds = _.isArray(fileIds) ? fileIds : [fileIds];

      var deferred = $q.defer();

      var promises = _.map(fileIds, function(id) {
        return $http({
          method: 'GET',
          url: '/services/data/v39.0/connect/files/' + id + '/previews',
          headers: {
            'Authorization': 'Bearer ' + window.sforce.connection.sessionId
          }
        });
      });

      $q.all(promises).then(function(responses) {
        var urls = _.map(responses, function(resp) {
          var data = resp.data;
          var thumbnailUrl = _.find(data.previews, function(d) {
            return d.format == 'ThumbnailBig';
          });
          if (thumbnailUrl.status === 'Available') {
            thumbnailUrl = thumbnailUrl.previewUrls[0].previewUrl;
          } else {
            thumbnailUrl = null;
          }
          return thumbnailUrl;
        });

        deferred.resolve(urls);
      }, deferred.reject);

      return deferred.promise;
    }

    function _validateStorageLimits(file) {
      var deferred = $q.defer();
      var BYTES_IN_2GB = 2000000000;

      if (file.size > BYTES_IN_2GB) {
        deferred.reject({
          data: [{
            errorCode: "MAX_FILE_SIZE_EXCEEDED",
            errorMessage: "Chatter Files does not support files larger than 2GB"
          }]
        });
      } else {
        //
        // Warning! This only works for System Admin with Salesforce License.
        // We will switch to an optimistic approach and remove the storage limit
        // verification.
        //
        // Ideally we wouldn't use REST API for this, but...
        // https://success.salesforce.com/ideaView?id=087300000006zM9AAI
        // $http({
        //   method: 'GET',
        //   url: '/services/data/v32.0/limits',
        //   headers: {
        //     'Authorization': 'Bearer ' + window.sforce.connection.sessionId,
        //     'Content-Type': 'application/json'
        //   }
        // }).then(function(result) {
        //   var remainingBytes = result.data.FileStorageMB.Remaining * 1000000;
        //   if ((remainingBytes - file.size) <= 0) {
        //     deferred.reject({
        //       data: [{
        //         errorCode: "STORAGE_LIMIT_EXCEEDED",
        //         errorMessage: "You don't have enough storage for " + file.name
        //       }]
        //     });
        //   } else {
        //     deferred.resolve();
        //   }
        // }, deferred.reject);

        //optimistic today
        deferred.resolve();
      }

      return deferred.promise;
    }

    return {
      writeFile: writeFile,
      deleteFile: deleteFile,
      readFile: readFile,
      readVersion: readVersion,
      readPreview: readPreview
    };
  }]);

  documentsApp.factory('attachmentsProvider', ['$q', function($q) {

    function deleteFile(fileIds) {
      var deferred = $q.defer();

      fileIds = _.isArray(fileIds) ? fileIds : [fileIds];

      sforce.connection.deleteIds(fileIds, {
        onSuccess: deferred.resolve,
        onFailure: deferred.reject
      });

      return deferred.promise;
    }

    function readFile(fileIds) {
      var deferred = $q.defer();

      fileIds = _.isArray(fileIds) ? fileIds : [fileIds];

      fileIds = _.map(fileIds, function(p) {
        return "'" + p + "'";
      });

      var query = "SELECT Id, ContentType, Body FROM Attachment WHERE Id IN (" + fileIds.join(',') + ") ORDER BY LastModifiedDate DESC";

      sforce.connection.query(query, {
        onSuccess: function(data) {
          var files = [];
          var it = new sforce.QueryResultIterator(data);
          while(it.hasNext()) {
            var record = it.next();
            files.push({path: record.Id, data: 'data:application/octet-stream;base64,' + record.Body });
          }

          deferred.resolve(files);
        },
        onFailure: deferred.reject
      });

      return deferred.promise;
    }

    function readPreview(path) {
      // Attachment records don't have a preview service, so we return the icon URL
      var deferred = $q.defer();
      deferred.resolve([window.litify.lightningAssetsBasePath + '/assets/icons/doctype/attachment_120.png']);
      return deferred.promise;
    }

    return {
      deleteFile: deleteFile,
      readFile: readFile,
      readPreview: readPreview
    };
  }]);

  /*
   * DOCUMENTS represents the litify_pm__LitifyDoc__c objects on Salesforce
   */
  documentsApp.factory('documentsService', ['$q', 'chatterFilesProvider', function($q, chatterFilesProvider) {
    var fs_array = null;
    var fs_tree = null;
    var FILE_BAD_CHARACTERS = /(\/|\.)/i;
    var MAX_UPDATE_CHUNK_SIZE = 200;

    function Node(args) {
      var props = ['type', 'path', 'name', 'parent', 'children', 'id', 'extension', 'file', 'description', 'tags', 'litify_doc', '_fetched'];
      for (var i = 0; i < props.length; i++) {
        var prop = props[i];
        if (args[prop]) {
          this[prop] = args[prop];
        }
      }
      this.nameSort = function() {
        return this.nameToDisplay || this.name;
      };
    }

    function _navigateToNodeWithPath(node, arrPath) {
      if (arrPath.length === 1) {
        return node.children[arrPath[0]];
      }

      var subFolder = node.children[_.first(arrPath)];
      return _navigateToNodeWithPath(subFolder, _.rest(arrPath));
    }
    function navigateToNodeWithPath(node, strPath) {
      if (strPath == '/') {
        return node;
      }

      return _navigateToNodeWithPath(node, _.rest(strPath.split('/')));
    }
    function getContainingNode(startingNode, filePathArray) {
      if (filePathArray.length === 1) {
        return startingNode;
      }

      var subfolder = _.first(filePathArray);
      var childNode = startingNode.children[subfolder];
      if (!childNode) {
        childNode = startingNode.children[subfolder] = new Node({
          type: 'folder',
          path: (startingNode.path[startingNode.path.length - 1] === '/' ? startingNode.path : startingNode.path + '/') + subfolder,
          name: subfolder,
          parent: startingNode,
          children: {},
        });
      }
      return getContainingNode(childNode, _.rest(filePathArray));
    }
    function addFileToNode(folderNode, fileToAdd) {
      var localFileName = _.last(fileToAdd.arrPath);

      folderNode.children[localFileName] = new Node({
        type: 'file',
        extension: fileToAdd.litify_pm__FileExtension__c,
        id: fileToAdd.Id,
        path: fileToAdd.litify_pm__Path__c,
        name: localFileName,
        file: fileToAdd,
        parent: folderNode
      });
    }
    //TODO: optimize!
    function _buildFSTree(sortedFiles, rootNode) {
      if (sortedFiles.length === 0) {
        return rootNode;
      }

      /*
       * /test
       * /bar/test
       * /foo/test
       * /foo/bar/test
       * /bar/foo/test
       */
      var currentFile = _.first(sortedFiles);
      var currentFilePathArray = _.rest(currentFile.arrPath);
      var fileFolder = getContainingNode(rootNode, currentFilePathArray);
      addFileToNode(fileFolder, currentFile);

      return _buildFSTree(_.rest(sortedFiles), rootNode);
    }

    function buildFSTree(allFiles) {
      var rootNode = { path: '/', name: '', type: 'folder', children: {}, root: true };

      if (allFiles.length === 0) {
        return rootNode;
      }

      // sort by depth of subdirectories
      var sortedFiles = _.sortBy(allFiles, function(file) {
        return file.arrPath.length;
      });

      return _buildFSTree(sortedFiles, rootNode);
    }

    function treeToArray(node, arr) {
      arr = arr || [];
      if (!node.children || node.children.length === 0) {
        return arr;
      }
      _.each(node.children, function(child) {
        arr.push(child);
        treeToArray(child, arr);
      });

      return arr;
    }

    function moveFolderOld(oldFolderPath, newFolderPath) {
      var deferred = $q.defer();

      var parentFolderPath = oldFolderPath.substring(0, oldFolderPath.lastIndexOf('/'));
      var folderPrefix = oldFolderPath + '/';

      if (!fs_array) {
        fs_array = treeToArray(fs_tree);
      }

      var docsToUpdate = _.chain(fs_array)
        .filter(function(file) {
          return file.type == 'file' && file.path.indexOf(folderPrefix) === 0;
        })
        .map(function(file) {
          var remainingPath = file.path.substring(oldFolderPath.length);
          var doc = new sforce.SObject('litify_pm__LitifyDoc__c');
          doc.id = file.id;
          doc.litify_pm__Path__c = newFolderPath + remainingPath;
          return doc;
        })
        .value();

      sforce.connection.update(docsToUpdate, {
        onSuccess: function(result) {
          fs_tree = null;
          fs_array = null;
          deferred.resolve(result);
        },
        onFailure: function(error) {
          deferred.reject(error);
        }
      });

      return deferred.promise;
    }

    function deleteFolder(path) {
      var deferred = $q.defer();

      if (path[path.length -1] != '/') {
        path = path + '/';
      }

      if (!fs_array) {
        fs_array = treeToArray(fs_tree);
      }

      var files_to_delete = _.filter(fs_array, function(file) {
        return file.type == 'file' && file.path.indexOf(path) === 0;
      });

      if (_.any(files_to_delete, function(f) { return f.name !== '.keep'; })) {
        deferred.reject('folder must be empty to delete');
        return;
      }

      var deleteIds = _.chain(files_to_delete)
        .map(function(f) {
          return [f.id, f.file.litify_pm__ProviderPath__c];
        })
        .flatten()
        .filter(function(f) { return !!f; })
        .value();

      sforce.connection.deleteIds(deleteIds, {
        onSuccess: function(result) {
          fs_tree = null;
          fs_array = null;
          deferred.resolve(result);
        },
        onFailure: function(error) {
          deferred.reject(error);
        }
      });
      return deferred.promise;
    }

    function uploadFile(file, path) {
      var deferred = $q.defer();
      var reader = new FileReader();
      reader.addEventListener('load', function() {
        var dataUrl = reader.result;
        var base64Data = dataUrl.substring(dataUrl.indexOf(',') + 1);
        var contentVersion = new sforce.SObject('ContentVersion');
        contentVersion.Title = file.name.replace(FILE_BAD_CHARACTERS, '_');
        contentVersion.PathOnClient = file.name;
        contentVersion.VersionData = base64Data;
        sforce.connection.create([contentVersion], {
          onSuccess: function(result) {
            var contentVersionId = result[0].id;
            sforce.connection.query("SELECT ContentDocumentId, FileExtension FROM ContentVersion WHERE Id = '" + contentVersionId + "'", {
              onSuccess: function(result) {
                var records = result.getArray('records');
                var contentDocumentId = records[0].ContentDocumentId;
                var newDoc = new sforce.SObject('litify_pm__LitifyDoc__c');
                newDoc.litify_pm__Path__c = path;
                newDoc.litify_pm__ProviderPath__c = contentDocumentId;
                newDoc.litify_pm__FileExtension__c = records[0].FileExtension;
                newDoc.litify_pm__RelatedTo__c = litify.page.currentObjectId;
                sforce.connection.create([newDoc], {
                  onSuccess: function(result) {
                    var documentId = result[0].id;
                    fs_tree = null;
                    fs_array = null;
                    deferred.resolve(documentId);
                  },
                  onFailure: function(error) {
                    console.log('error creating document', error);
                    deferred.reject(error);
                  }
                });
              },
              onFailure: function(error) {
                console.log('error getting ContentDocumentId', error);
                deferred.reject(error);
              }
            });
          },
          onFailure: function(error) {
            console.log('Error uploading ContentVersion', error);
            deferred.reject(error);
          }
        });
      }, false);
      reader.readAsDataURL(file);

      return deferred.promise;
    }

    function testFilename(name) {
      return name && !FILE_BAD_CHARACTERS.test(name);
    }

    function _initDir(dir) {
      var deferred = $q.defer();
      window.addEventListener("initDirApexFunctionCompleted", function(e) {
        deferred.resolve();
      }, false);
      initDirApexFunction(dir);
      return deferred.promise;
    }

    function _sortFoldersByName(folders) {
      return _.sortBy(folders, function (folder) {
          return folder.litify_pm__Path__c.toLowerCase();
      });
    }

    // refactored
    function getLitifyDocuments(path, includeSubDirectories) {
      var deferred = $q.defer();
      _initDir(path).then(function() {
        path = path || '/';
        var query = "SELECT Id, Name, litify_pm__Description__c, litify_pm__Tags__c, litify_pm__ProviderPath__c, litify_pm__Path__c, litify_pm__FetchOnPath__c, litify_pm__FileExtension__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name FROM litify_pm__LitifyDoc__c WHERE litify_pm__FetchOnPath__c ";
        if (!includeSubDirectories) {
          query += "= '" + path + "'";
        } else {
          query += ("LIKE '" + path + "%'");
        }
        sforce.connection.query(query, {
          onSuccess: function(data) {
            var folders = [];
            var documents = [];
            var it = new sforce.QueryResultIterator(data);
            while(it.hasNext()){
              var doc = it.next();
              if (doc.litify_pm__Path__c.indexOf(path) === 0) {
                // add only if doc.litify_pm__Path__c starts with current path
                if (doc.litify_pm__FileExtension__c === 'keep') {
                  folders.push(doc);
                } else {
                  documents.push(doc);
                }
              }
            }
            folders = _sortFoldersByName(folders);
            deferred.resolve(folders.concat(documents));
          },
          onFailure: deferred.reject
        });
      }, deferred.reject);
      return deferred.promise;
    }

    function getLitifyDocumentsWithSubDirs(path) {
      return getLitifyDocuments(path, true);
    }

    function createOrUpdateLitifyDocument(path, providerPath, litifyDoc) {
      if (!litifyDoc) {
        return createLitifyDocument(path, providerPath, litifyDoc);
      } else {
        return updateLitifyDocument(path, providerPath, litifyDoc);
      }
    }
    function createLitifyDocument(path, providerPath, litifyDoc) {
      var deferred = $q.defer();
      var filename = _.last(path.split('/'));
      var extension = _.last(filename.split('.'));

      var newDoc = new sforce.SObject('litify_pm__LitifyDoc__c');
      newDoc.litify_pm__Path__c = path;
      newDoc.litify_pm__ProviderPath__c = providerPath;
      newDoc.litify_pm__FileExtension__c = extension;
      newDoc.litify_pm__RelatedTo__c = litify.page.currentObjectId;
      sforce.connection.create([newDoc], {
        onSuccess: function(result) {
          newDoc.Id = result[0].id;
          window.litify.page.lastInsertedOrUpdatedObjectId = newDoc.Id;
          var query = "SELECT Id, Name, litify_pm__Description__c, litify_pm__Tags__c, litify_pm__ProviderPath__c, litify_pm__Path__c, litify_pm__FileExtension__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name FROM litify_pm__LitifyDoc__c WHERE ID = '" + result[0].id + "'";
          sforce.connection.query(query, {
            onSuccess: function(data) {
              deferred.resolve(data.records);
            },
            onFailure: deferred.reject
          });
        },
        onFailure: deferred.reject
      });

      return deferred.promise;
    }
    function updateLitifyDocument(path, providerPath, litifyDoc) {
      var deferred = $q.defer();
      var filename = _.last(path.split('/'));
      var extension = _.last(filename.split('.'));

      var docToUpdate = new sforce.SObject('litify_pm__LitifyDoc__c');
      docToUpdate.Id = litifyDoc.id;
      docToUpdate.litify_pm__Path__c = path;
      docToUpdate.litify_pm__ProviderPath__c = providerPath;
      docToUpdate.litify_pm__FileExtension__c = extension;
      docToUpdate.litify_pm__RelatedTo__c = litify.page.currentObjectId;

      sforce.connection.update([docToUpdate], {
        onSuccess: function(result) {
          window.litify.page.lastInsertedOrUpdatedObjectId = result[0].id;
          var query = "SELECT Id, Name, litify_pm__Description__c, litify_pm__Tags__c, litify_pm__ProviderPath__c, litify_pm__Path__c, litify_pm__FileExtension__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name FROM litify_pm__LitifyDoc__c WHERE ID = '" + result[0].id + "'";
          sforce.connection.query(query, {
            onSuccess: function(data) {
              deferred.resolve(data.records);
            },
            onFailure: deferred.reject
          });
        },
        onFailure: deferred.reject
      });

      return deferred.promise;
    }

    function _updateDocuments(documents) {
      var deferred = $q.defer();
      sforce.connection.update(documents, {
        onSuccess: deferred.resolve,
        onFailure: deferred.reject
      });
      return deferred.promise;
    }

    function _updateDocsInChunks(chunks, deferred) {
      $q.all(_.map(chunks, _updateDocuments))
        .then(function(responses) {
          deferred.resolve(_.flatten(responses));
        }, deferred.reject);
    }

    function moveFile(zippedIdsAndFilePaths) {
      var idsWithPaths = zippedIdsAndFilePaths;

      var sfDocs = [];
      _.each(idsWithPaths, function(idWithPath) {
        var doc = new sforce.SObject('litify_pm__LitifyDoc__c');
        doc.id = idWithPath[0];
        doc.litify_pm__Path__c = idWithPath[1];
        sfDocs.push(doc);
      });
      var deferred = $q.defer();
      var sfDocsChunks = [];
      var sfDocsChunk = _.first(sfDocs, MAX_UPDATE_CHUNK_SIZE);
      while (sfDocsChunk.length) {
        sfDocsChunks.push(sfDocsChunk);
        sfDocs = _.rest(sfDocs, MAX_UPDATE_CHUNK_SIZE);
        sfDocsChunk = _.first(sfDocs, MAX_UPDATE_CHUNK_SIZE);
      }
      _updateDocsInChunks(sfDocsChunks, deferred);
      return deferred.promise;
    }

    function deleteFile(fileIds) {
      var deferred = $q.defer();

      var fileIds = _.isArray(fileIds) ? fileIds : [fileIds];
      sforce.connection.deleteIds(fileIds, {
        onSuccess: function(result) {
          deferred.resolve(result);
        },
        onFailure: function(error) {
          deferred.reject(error);
        }
      });
      return deferred.promise;
    }

    function createFolder(path) {
      var deferred = $q.defer();

      var folder = new sforce.SObject('litify_pm__LitifyDoc__c');
      folder.litify_pm__Path__c = encodeURI(path + '/.keep');
      folder.litify_pm__RelatedTo__c = litify.page.currentObjectId;
      folder.litify_pm__FileExtension__c = 'keep';
      sforce.connection.create([folder], {
        onSuccess: function(records) {
          window.litify.page.lastInsertedOrUpdatedObjectId = records[0].id;
          var query = "SELECT Id, Name, litify_pm__Description__c, litify_pm__Tags__c, litify_pm__ProviderPath__c, litify_pm__Path__c, litify_pm__FileExtension__c, CreatedDate, CreatedBy.Name, LastModifiedDate, LastModifiedBy.Name FROM litify_pm__LitifyDoc__c WHERE ID = '" + records[0].id + "'";
          sforce.connection.query(query, {
            onSuccess: function(data) {
              deferred.resolve(data.records);
            },
            onFailure: deferred.reject
          });
        },
        onFailure: function(error) {
          deferred.reject(error);
        }
      });

      return deferred.promise;
    }

    // TODO: Refactor these to use providers
    function supportsVersions(file) {
      var providerPath = file.litify_doc.litify_pm__ProviderPath__c;
      if (providerPath && providerPath.startsWith('00P')) {
        return false;
      }

      return true;
    }

    function getVersions(file) {
      var deferred = $q.defer();
      if (!supportsVersions(file)) {
        deferred.resolve([]);
        return deferred.promise;
      }
      var query = "SELECT Id, Title, VersionNumber, LastModifiedBy.Name, LastModifiedDate FROM ContentVersion WHERE ContentDocumentId = '" + file.litify_doc.litify_pm__ProviderPath__c + "'";
      sforce.connection.query(query, {
        onSuccess: function(result) {
          var versions = [];
          var it = new sforce.QueryResultIterator(result);
          while(it.hasNext()) {
            var version = it.next();
            var modifiedDate = new Date(version.LastModifiedDate);
            version.LastModifiedDate = modifiedDate.toLocaleDateString() + " " + modifiedDate.toLocaleTimeString();
            versions.push(version);
          }
          var sortedVersions = _.sortBy(versions, function(v) { return parseInt(v.VersionNumber); }).reverse();
          deferred.resolve(sortedVersions);
        },
        onFailure: deferred.reject
      });
      return deferred.promise;
    }

    return {
      deleteFolder: deleteFolder,
      uploadFile: uploadFile,
      moveFolder: moveFolderOld,
      testFilename: testFilename,
      getLitifyDocuments: getLitifyDocuments,
      getLitifyDocumentsWithSubDirs: getLitifyDocumentsWithSubDirs,
      createOrUpdateLitifyDocument: createOrUpdateLitifyDocument,
      moveFile: moveFile,
      deleteFile: deleteFile,
      createFolder: createFolder,
      Node: Node,

      supportsVersions: supportsVersions,
      getVersions: getVersions
    };
  }]);

  /*
   * FILESYSTEM represents the cached filesystem in the browser
   */
  documentsApp.factory('filesystem', ['$q', '$http', 'documentsService', 'chatterFilesProvider', 'attachmentsProvider', function($q, $http, documentsService, chatterFilesProvider, attachmentsProvider) {
    var fs_tree = { path: '/', type: 'folder', name: '', children: [], _fetched: false };
    var CONTENT_VERSION_ID_PREFIX = '069';
    var ATTACHMENT_PREFIX = '00P';

    function litifyDocToFileNode(doc) {
      var path = doc.litify_pm__Path__c;
      var extension = doc.litify_pm__FileExtension__c;

      return new documentsService.Node({
        path: path,
        type: extension === 'symlink' ? 'symlink' : 'file',
        extension: extension,
        description: doc.litify_pm__Description__c,
        tags: _.without((doc.litify_pm__Tags__c || '').split(';'), ''),
        id: doc.Id,
        name: _.last(path.split('/')),
        litify_doc: doc
      });
    }

    function _addNodeToFilesystem(node, pathArray, parentNode) {
      var pathHead = _.first(pathArray);
      var pathTail = _.rest(pathArray);

      if (pathTail.length === 0) { // this is the correct directory
        node.parent = parentNode;
        if (pathHead === '.keep') {
          node.parent.litify_doc = node.litify_doc;
        }
        parentNode.children = parentNode.children || [];

        parentNode.children = _.reject(parentNode.children, function(child) { return child.id == node.id; });
        parentNode.children.push(node);
        return;
      }

      var childNode = _.find(parentNode.children, function(child) {
        return child.type === 'folder' && child.name === pathHead;
      });

      if (!childNode) {
        // create folder node
        childNode = new documentsService.Node({
          path: (parentNode.path == '/' ? parentNode.path : parentNode.path + '/') + pathHead,
          type: 'folder',
          name: pathHead,
          parent: parentNode,
          children: [],
          _fetched: false
        });

        var lastNode = _.last(parentNode.children);
        if (lastNode && (lastNode.type !== 'folder' && lastNode.extension !== 'keep')) {
          // insert new folder to top of list
          parentNode.children.unshift(childNode);
        } else {
          parentNode.children.push(childNode);
        }
      }

      _addNodeToFilesystem(node, pathTail, childNode);
    }

    function addNodeToFilesystem(fileNode) {
      _addNodeToFilesystem(fileNode, _.rest(fileNode.path.split('/')), fs_tree);
    }

    function resolveSObjectName(nodes) {
      var filteredNodes = _.filter(nodes, function(node) {
        var sObjectName = _.last(node.path.split('/'));
        return node.type === 'folder' && /(INT-\d+)|(MAT-\d+)/.test(sObjectName);
      });
      var filteredNodePaths = _.map(filteredNodes, function(node) {
        return node.path;
      });
      if (nodes !== []) {
        getSObjectNameToDisplayApexFunction(filteredNodePaths, function(sObjectNameToDisplayResults) {
          _.each(filteredNodePaths, function(path) {
            var foundNode = _.find(filteredNodes, function(node) {
              return node.path === path;
            });
            var sObjectNameToDisplay = sObjectNameToDisplayResults[path];
            if (sObjectNameToDisplay) {
              foundNode.nameToDisplay = sObjectNameToDisplay;
            }
          });
        });
      }
    }

    function _processAllFolderNodesToAddTheNameToDisplay(fs_tree) {
      var folderNodesAccum = [];
      _recursiveProcessAllFolderNodesToAddTheNameToDisplay(fs_tree.children, folderNodesAccum);
      resolveSObjectName(folderNodesAccum);
    }

    function _recursiveProcessAllFolderNodesToAddTheNameToDisplay(children, folderNodesAccum) {
      if (!children || children.length === 0) {
        return;
      }
      _.each(children, function(child) {
        if (child.type === 'folder' && !child.nameToDisplay) {
          folderNodesAccum.push(child);
        }
        _recursiveProcessAllFolderNodesToAddTheNameToDisplay(child.children, folderNodesAccum);
      });
    }

    function _cleanFolder(folderNode) {
      folderNode.children = _.filter(folderNode.children, function(n) {
        return n.path === folderNode.path + '/.keep';
      });
    }

    function _addLitifyDocsToFilesystem(documents) {
      // once documents are retrieved:
            //    convert documents to nodes
            //    add each node to filesystem
            //    resolve promise
      _.chain(documents)
        .map(litifyDocToFileNode)
        .each(addNodeToFilesystem);
    }

    function readdir(path) {
      var pathArray, deferred = $q.defer();
      if (path !== "/") {
        // remove trailing slash, in case path == '/MAT-123/'
        if (path[path.length - 1] === '/') {
          path = path.substring(0, path.length - 1);
        }
      }

      var nodeAtPath = _findNodeAtPath(path, fs_tree);

      // If looking for a path that doesn't exist (as a node), findNodeAtPath returns fs_tree
      if (path !== "/" && nodeAtPath === fs_tree) {
        nodeAtPath = new documentsService.Node({
          path: path,
          type: 'folder',
          name: _.last(path.split('/')),
          children: [],
          _fetched: false,
        });
        addNodeToFilesystem(nodeAtPath);
      }

      if (nodeAtPath._fetched) {
        deferred.resolve(nodeAtPath.children);
      } else {
        // fetch documents at path
        documentsService.getLitifyDocuments(nodeAtPath.path)
          .then(function(documents) {
            nodeAtPath._fetched = true;
            _cleanFolder(nodeAtPath);
            _addLitifyDocsToFilesystem(documents);
            _processAllFolderNodesToAddTheNameToDisplay(fs_tree);
            deferred.resolve(nodeAtPath.children);
          }, deferred.reject);
      }
      return deferred.promise;
    }

    function writeFile(path, file, progressCb, litifyDoc) {
      var deferred = $q.defer();

      var _progressCb = function(evt) {
        if (_.isFunction(progressCb)) {
          evt.file = file;
          progressCb(evt);
        }
      };

      chatterFilesProvider.writeFile(path, file, _progressCb, litifyDoc).then(
      function(providerPath) {
        documentsService.createOrUpdateLitifyDocument(path, providerPath, litifyDoc).
        then(function(doc) {
          var node = litifyDocToFileNode(doc);
          addNodeToFilesystem(node);
          deferred.resolve(node);
        }, deferred.reject);
      }, deferred.reject);

      return deferred.promise;
    }

    function readFile(paths) {
      // Paths can be Attachments/ContentVersion. We will split depending on object using record ID prefix
      // See: https://help.salesforce.com/articleView?id=Standard-Field-Record-ID-Prefix-Decoder&type=1
      var contentVersionPaths = _.filter(paths, function(path){
        return path.startsWith('069');
      });
      var attachmentPaths = _.filter(paths, function(path){
        return path.startsWith('00P');
      });

      var promises = [];
      if (attachmentPaths.length > 0) {
        var attachmentsPromise = attachmentsProvider.readFile(attachmentPaths);
        promises.push(attachmentsPromise);
      }

      if (contentVersionPaths.length > 0) {
        var chatterFilesPromise = chatterFilesProvider.readFile(contentVersionPaths);
        promises.push(chatterFilesPromise);
      }

      return $q.all(promises);
    }

    function readVersion(versionId) {
      return chatterFilesProvider.readVersion(versionId);
    }

    function previewFile(path) {
      if (path && path.startsWith(CONTENT_VERSION_ID_PREFIX)) {
        return chatterFilesProvider.readPreview(path);
      } else if (path && path.startsWith(ATTACHMENT_PREFIX)) {
        return attachmentsProvider.readPreview(path);
      }
    }

    function _searchFileNodes(node, workingDir, keyword, results) {
      var matches = {};
      if (node.name.fuzzySearch(keyword)) {
        matches.name = true;
      }
      if (node.description && node.description.fuzzySearch(keyword)) {
        matches.description = true;
      }
      if (node.tags && _.any(node.tags, function(t) { return t.fuzzySearch(keyword); })) {
        matches.tags = true;
      }

      if (_.keys(matches).length) {
        results.push({fd: node, matches: matches});
      }


      _.each(node.children, function(child) { _searchFileNodes(child, workingDir, keyword, results); });

    }

    function searchFileNodes(path, keyword) {
      console.log('gonna search ' + path + ' for ' + keyword);
      // todo: if searching root path use provider (SOSL)
      var deferred = $q.defer();
      readdir(path).then(function(childNodes) {
        var results = [];
        _.each(childNodes, function(node) {
          _searchFileNodes(node, path, keyword, results);
        });
        deferred.resolve(results);
      }, deferred.reject);
      return deferred.promise;
    }

    function _findNodeAtPath(path, currentNode) {
      currentNode = currentNode || fs_tree;
      path = _.isArray(path) ? path : _.rest(path.split('/'));

      if (!path.length) {
        return currentNode;
      }

      var subNodeName = _.first(path);
      var rest = _.rest(path);

      var subNode = _.findWhere(currentNode.children, {name: subNodeName});
      return _findNodeAtPath(rest, subNode);
    }

    function _getAllFilesUnderNode(node, acc) {
      acc = acc || [];
      _.each(node.children || [], function(child) {
        if (child.type === 'file' || child.type === 'symlink') {
          acc.push(child);
        } else {
          _getAllFilesUnderNode(child, acc);
        }
      });

      return acc;
    }

    function _zipLitifyDocIdsAndNewPaths(nodes, oldPath, newPath) {
      oldIds = _.pluck(nodes, 'id');
      newPaths = _.map(_.pluck(nodes, 'path'), function(path) {
        return newPath + path.substring(oldPath.length);
      });
      return _.zip(oldIds, newPaths);
    }

    function rename(oldPath, newPath) {
      var deferred = $q.defer();
      var oldNode = _findNodeAtPath(oldPath);
      // If oldNode doesn't exist, _findNodeAtPath returns '/'
      if (oldPath !== "/" && oldNode.path === '/') {
        // But if oldPath and oldNode.path differ it means something's wrong.
        // We don't want to work with our inexistent node as if it was root.
        deferred.reject('oldNode with path: ' + oldPath + ' was not found');
        return deferred.promise;
      }
      var newPathArray = newPath.split('/');
      var newParentNode = _findNodeAtPath(_.rest(_.first(newPathArray, newPathArray.length - 1)));

      if (oldNode.type === 'folder' && (newParentNode === oldNode)) {
          deferred.reject('Cannot rename a folder to its current name');
          return deferred.promise;
      }

      var oldIds, newPaths;
      if (oldNode.type === 'file' || oldNode.type === 'symlink') {
        oldIds = oldNode.id;
        documentsService.moveFile([[oldNode.id, newPath]])
          .then(function() {
            oldNode.parent._fetched = false;
            newParentNode._fetched = false;
            deferred.resolve();
          }, deferred.reject);
      } else if (oldNode.type === 'folder') {
        // Get all subdirectories and files inside oldNode
        documentsService.getLitifyDocumentsWithSubDirs(oldNode.path)
          .then(function(documents) {
            oldNode._fetched = true;
            _cleanFolder(oldNode);
            _addLitifyDocsToFilesystem(documents);
            // now that docs are in fs_tree under oldNode, get them
            var nodes = _getAllFilesUnderNode(oldNode);
            documentsService.moveFile(_zipLitifyDocIdsAndNewPaths(nodes, oldPath, newPath))
              .then(function() {
                oldNode.parent._fetched = false;
                newParentNode._fetched = false;
                deferred.resolve();
              }, deferred.reject);
          }, deferred.reject);
      } else {
        deferred.reject('invalid node type ' + oldNode.type);
        return deferred.promise;
      }
      return deferred.promise;
    }

    function _delete(doc_ids, provider_ids, deferred) {
      documentsService.deleteFile(doc_ids).then(function() {
        if (doc_ids.length) {
          chatterFilesProvider.deleteFile(doc_ids).then(deferred.resolve, deferred.reject);
        } else {
          deferred.resolve();
        }
      }, deferred.reject);
    }

    function unlink(path) {
      var deferred = $q.defer();
      var node = _findNodeAtPath(path);

      if (!node) {
        deferred.reject('path not found');
        return deferred.promise;
      }

      var doc_ids, provider_ids;
      switch (node.type) {
        case 'folder':
          // Get all subdirectories and files inside oldNode
          documentsService.getLitifyDocuments(node.path)
            .then(function(documents) {
              node._fetched = true;
              _cleanFolder(node);
              _addLitifyDocsToFilesystem(documents);
              if (node.children.length > 1) {
                deferred.reject('Cannot delete folder containing files');
              } else {
                var nodes = _getAllFilesUnderNode(node);
                doc_ids = _.pluck(nodes, 'id');
                provider_ids = _.chain(nodes).pluck('litify_pm__ProviderPath__c').reject(function(x) { return !x; }).value();
                var parent = node.parent;
                parent.children = _.without(parent.children, node);
                _delete(doc_ids, provider_ids, deferred);
              }
            }, deferred.reject);
            break;
        case 'file':
          provider_ids = node.litify_doc.litify_pm__ProviderPath__c;
        case 'symlink':
          doc_ids = node.id;
          var parent = node.parent;
          parent.children = _.without(parent.children, node);
          _delete(doc_ids, provider_ids, deferred);
          break;
        default:
          deferred.reject('invalid node type ' + node.type);
      }
      return deferred.promise;
    }

    function mkdir(path) {
      var deferred = $q.defer();
      documentsService.createFolder(path).then(function(doc) {
        addNodeToFilesystem(litifyDocToFileNode(doc));
        deferred.resolve();
      }, deferred.reject);
      return deferred.promise;
    }

    function refreshFiles(files) {
      files.forEach(function(f) {
        f.parent._fetched = false;
      });
    }

    // attempted to model after https://nodejs.org/api/fs.html where possible
    return {
      _filesystem: fs_tree,
      readdir: readdir,
      writeFile: writeFile,
      readFile: readFile,
      readVersion: readVersion,
      previewFile: previewFile,
      rename: rename,
      mv: rename,
      search: searchFileNodes,
      unlink: unlink,
      mkdir: mkdir,
      refreshFiles: refreshFiles,
      resolveSObjectName: resolveSObjectName
    };
  }]);

  documentsApp.factory('navigationService', function($rootScope) {
    return {
      pathChanged: function(path, isSymlink) {
        $rootScope.$broadcast('pathChanged', { path: path, isSymlink: isSymlink });
      },
    };
  });

  documentsApp.filter('localFileName', function() {
    return function(fullPath) {
      if (!fullPath || fullPath.length === 0) {
        return fullPath;
      }


      return _.last(fullPath.split('/'));
    };
  });

  var _hideExtension = function(fileName) {
    if (fileName.lastIndexOf('.') > -1) {
      fileName = fileName.substring(0, fileName.lastIndexOf('.'));
    }
    return fileName;
  };

  documentsApp.filter('hideExtension', function() {
    return _hideExtension;
  });

  documentsApp.filter('nodeNameToDisplay', function() {
    return function(node) {
      return node.nameToDisplay ? decodeURI(node.nameToDisplay) : decodeURI(_hideExtension(node.name));
    };
  });

  documentsApp.filter('highlight', ['$sce', function($sce) {
    return function(text, needles) {
      if (!needles || !needles.length) {
        return $sce.trustAsHtml(text);
      }

      text = text || '';
      var result = '', haystack = text, lower_haystack = text.toLowerCase();
      needles = needles.toLowerCase();
      var needle_index = 0;

      for (var i = 0 ; i < haystack.length ; i++) {
        if (lower_haystack[i] == needles[needle_index]) {
          needle_index++;
          result += '<b class="slds-text-color--default">' + haystack[i] + '</b>';
        } else {
          result += haystack[i];
        }
      }

      return $sce.trustAsHtml(result);
    };
  }]);

}(jQuery, window.litify));
