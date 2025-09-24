(function(jQuery, litify) {
  var documentsApp = angular.module('documentsApp');

  documentsApp.directive('documents', function() {
    return {
      restrict: 'E',
      templateUrl: litify.page.getTemplateUrl('documents.html'),
      scope: {
        basePath: '<'
      },
      link: function(scope, elm, attrs, ctrl) {
        scope.currentPath = scope.basePath || '/';
        scope.searchText = '';
      }
    };
  });
  // document path name validator
  documentsApp.directive('documentPath', ['documentsService', function(documentsService) {
    return {
      require: 'ngModel',
      link: function(scope, elm, attrs, ctrl) {
        ctrl.$validators['document-path'] = function(modelValue, viewValue) {
          if (ctrl.$isEmpty(modelValue)) {
            return false;
          }

          return documentsService.testFilename(modelValue);
        };
      }
    };
  }]);

  documentsApp.directive('documentFolderBreadcrumbs', ['navigationService', 'filesystem', function(navigationService, filesystem) {
    return {
      restrict: 'E',
      scope: {
        currentPath: '='
      },
      templateUrl: litify.page.getTemplateUrl('document_folder_breadcrumbs.html'),
      link: function($scope) {
        $scope.changeCurrentPath = function(path) {
          $scope.currentPath = path;
          navigationService.pathChanged(path);
        };
        $scope.$on('pathChanged', function(evt, args) {
          $scope.currentPath = args.path;
          $scope.changedPathFromSymlink = args.isSymlink;
        });
        var breadcrumbNodesByPath = {};
        $scope.$watch('currentPath', function(newPath, oldPath) {
          var currentPath = $scope.currentPath;
          var currentPathArray = currentPath.split('/');

          var breadcrumbs = [];
          var newBreadcrumbsThatNeedNameResolving = [];
          breadcrumbs.push({
            name: 'Documents',
            path: '/'
          });

          var realPath;
          if ($scope.changedPathFromSymlink) {
            realPath = oldPath.concat(currentPath);
            breadcrumbs.push(breadcrumbNodesByPath[oldPath]);
          } else {
            var symlinkPath = _.findKey(breadcrumbNodesByPath, { 'type': 'symlink', 'name': currentPathArray[1] });
            if (currentPath.startsWith(symlinkPath)) {
              var symlink = breadcrumbNodesByPath[symlinkPath];
              var sourceDir = symlink.realpath.replace(symlinkPath, '');
              breadcrumbs.push(breadcrumbNodesByPath[sourceDir]);
            }
          }

          var relativePathArray = _.rest(currentPathArray, 1);
          _.each(relativePathArray, function(val, idx, lst) {
            var breadcrumbPath = '/' + _.first(lst, idx + 1).join('/');
            var existingBreadcrumbNode = breadcrumbNodesByPath[breadcrumbPath];
            if (existingBreadcrumbNode) {
              breadcrumbs.push(existingBreadcrumbNode);
            } else {
              var newBreadcrumb = {
                name: val,
                type: $scope.changedPathFromSymlink ? 'symlink' : 'folder',
                path: breadcrumbPath,
                realpath: realPath
              };
              breadcrumbs.push(newBreadcrumb);
              newBreadcrumbsThatNeedNameResolving.push(newBreadcrumb);
              breadcrumbNodesByPath[breadcrumbPath] = newBreadcrumb;
            }
          });
          filesystem.resolveSObjectName(newBreadcrumbsThatNeedNameResolving);
          $scope.currentPathArray = breadcrumbs;
        });
      }
    };
  }]);

  documentsApp.directive('filesList', ['navigationService', 'filesystem', 'NgTableParams', '$q', '$templateCache', 'Upload', 'ngProgressFactory', 'documentsService', function(navigationService, filesystem, NgTableParams, $q, $templateCache, Upload, ngProgressFactory, documentsService) {
    return {
      restrict: 'E',
      scope: {
        currentPath: '=',
        searchTerm: '<'
      },
      templateUrl: litify.page.getTemplateUrl('files_list.html'),
      link: function($scope) {
        $scope.progressbar = ngProgressFactory.createInstance();
        $scope.selectedFiles = [];
        var errorRenaming = function(err) {
          if (err) {
            $scope.alertOptions = {
              show: true,
              title: 'Error renaming file',
              message: err,
              hideButtons: true
            };
          }
          console.log(err);
        };
        var startLoading = function() {
          $scope.isUploading = 1;
          $scope.progressbar.set(1);
        };
        var stopLoading = function() {
          $scope.isUploading = 0;
          $scope.progressbar.complete();
        };

        $scope.dropValidate = function(target, source) {
          console.log(target, source);
          return $scope.currentPath !== '/' && target.fd.type == 'folder';
        }
        $scope.onDrop = function(source, target) {
          var folderPath = target.path;
          if (folderPath[folderPath.length - 1] != '/') {
            folderPath = folderPath + '/';
          }

          var moveFile = function(f) {
            startLoading();

            filesystem.rename(f.path, folderPath + f.name)
              .then(
                function(res){
                  stopLoading();
                  refreshFilter(res);
                },
                function(err) {
                  stopLoading();
                  errorRenaming(err);
                });
          };
          // move all selected files
          $scope.selectedFiles.forEach(moveFile);

          if (!_.any($scope.selectedFiles, function(f) { return f.path == source.path; })) {
            // item dragged is not in selected files - move it too
            moveFile(source);
          }

          $scope.selectedFiles = [];
        };

        $scope.$on('pathChanged', function(event, args) {
          $scope.currentPath = args.path;
        });

        $scope.tableParams = new NgTableParams({}, {counts: []});
        var contextMenu = jQuery('#context-menu');

        $scope.some = _.some;
        $scope.isInRootFolder = function(file) {
          return file && file.parent && file.parent.parent && file.parent.parent.path === '/';
        };

        $scope.getFileIcon = function(file) {
          if (file.type === 'folder') {
            return 'folder';
          }
          if (file.type === 'symlink') {
            return 'link';
          }

          if (!file.extension) {
            return 'unknown';
          }

          var extension = file.extension && file.extension.toLowerCase();

          switch(file.extension) {
            case 'wav':
            case 'mp3':
            return 'audio';

            case 'xls':
            case 'xlsx':
            return 'excel';

            case 'fla':
            return 'flash';

            case 'aaf':
            case 'm4v':
            case 'ogg':
            case 'avi':
            case 'asf':
            return 'video';

            case 'gif':
            case 'jpg':
            case 'jpeg':
            case 'png':
            return 'image';

            case 'doc':
            case 'docx':
            return 'word';

            case 'ppt':
            case 'pptx':
            return 'ppt';

            case 'html':
            case 'htm':
            return 'html';

            case 'rtf':
            case 'pdf':
            case 'xml':
            case 'zip':
            case 'txt':
            case 'xml':
            case 'csv':
            case 'eps':
            case 'exe':
            case 'mp4':
            case 'ai':
            return file.extension;

            default:
            return 'unknown';
          }
        };
        $scope.openSalesforcePreview = function(files) {
          if (!(files instanceof Array)) {
            files = [files];
          }
          var windowOnMouseOver = window.onmouseover;
          if (!windowOnMouseOver) {
            var f = filesystem;
            window.onmouseover = function() {
              f.refreshFiles(files);
              refreshFilter();
              window.onmouseover = windowOnMouseOver;
            };
          }
          // https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage
          parent.postMessage({
            type: "shareFile",
            recordIds: files.map(function(e) { return e.litify_doc.litify_pm__ProviderPath__c; })
          }, "*");
        };

        var createLinkAndDownloadFile = function(fileRes) {
          var link = document.createElement('a');
          link.href = fileRes.downloadUrl;
          link.target = '_blank';
          link.download = fileRes.fileName;
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        };

        $scope.download = function(files) {
          if (!(files instanceof Array)) {
            files = [files];
          }

          var paths = _.reduce(files, function(acc, file) {
            var providerPath = file.litify_doc.litify_pm__ProviderPath__c;
            if (!!providerPath) acc.push(providerPath);
            return acc;
          }, []);

          filesystem.readFile(paths).then(function(allPromisesResult) {
            _.each(allPromisesResult, function(responses) {
              _.each(responses, createLinkAndDownloadFile);
            });
          }, console.log);
        };

        $scope.downloadVersion = function(version) {
          filesystem.readVersion(version.Id).then(createLinkAndDownloadFile, console.log);
        };

        $scope.handleDoubleClick = function(evt) {
          var file = getFileFromEvent(evt);
          $scope.selectedFiles = [file];

          if (file.type === 'file') {
            $scope.showFilePreview(file);
          }
          if (file.type === 'folder') {
            $scope.currentPath = file.path;
            $scope.searchTerm = '';
          }
          if (file.type === 'symlink') {
            $scope.currentPath = file.litify_doc.litify_pm__ProviderPath__c;
            $scope.searchTerm = '';
            $scope.isSymlink = true;
          }
        };

        $scope.updateFileDescription = function(file) {
          window.clearTimeout(file._updateDescriptionTimeoutID);
          file._updateDescriptionTimeoutID = window.setTimeout(function() {
            // update description
            var doc = new sforce.SObject('litify_pm__LitifyDoc__c');
            doc.id = file.id;
            doc.litify_pm__Description__c = file.description;
            sforce.connection.update([doc], {
              onSuccess: function(result) {
              },
              onFailure: function(error) {
                console.log(error);
              }
            });
          }, 2500);
        };

        $scope.showFilePreview = function(file) {
          var previewFileContext = {
            file: file,
            previewUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=',
            versions: []
          };

          if (!file.litify_doc.litify_pm__ProviderPath__c) return;

          filesystem.previewFile(file.litify_doc.litify_pm__ProviderPath__c).then(function(urls) {
            var url = urls[0];
            previewFileContext.previewUrl = url;
          });
          documentsService.getVersions(file).then(function(versions) {
            previewFileContext.versions = versions;
          })

          $scope.previewFileContext = previewFileContext;
          $scope.isShowFilePreview = true;
        };

        $scope.showVersions = function() {
          $scope.versions = $scope.previewFileContext.versions;
          $scope.isShowVersions = true;
        };

        function getFileFromEvent(evt) {
          var targetRow = evt.target.closest('tr');
          var targetFileId = targetRow.getAttribute('data-node-id');
          var targetFilePath = targetRow.getAttribute('data-node-path');

          if (targetFileId) {
            return _.find($scope.files, function(f) { return f.id == targetFileId; });
          } else if(targetFilePath) {
            // this is a folder
            return _.find($scope.files, function(f) { return f.path == targetFilePath; });
          }
          return null;
        };

        window.addEventListener('keypress', function(e) {
          if ($scope.showRenameFile || $scope.showFilePreview) {
            return;
          }

          if ($scope.selectedFiles.length != 1) {
            return;
          }

          if (e.keyCode != 13/* enter */) {
            return;
          }

          var file = $scope.selectedFiles[0];

          switch(file.type) {
            case 'file':
            $scope.showFilePreview(file);
            break;
            case 'folder':
            $scope.currentPath = file.path;
            break;
          }
        }, false);

        $scope.isSelected = function(file) {
          return _.contains($scope.selectedFiles, file);
        };

        $scope.toggleSelected = function(file) {
          var idx = _.indexOf($scope.selectedFiles, file);
          if (idx >= 0) {
            $scope.selectedFiles.splice(idx, 1);
          } else {
            $scope.selectedFiles.push(file);
          }
        };

        $scope.handleClick = function(evt) {
          $scope.newOpenDialog = false;
          contextMenu.hide();

          // don't handle clicks on checkbox!
          if (evt.target.className == 'slds-checkbox--faux') {
            return;
          }

          var file = getFileFromEvent(evt);

          if (file && evt.which === 1) {
            $scope.selectedFiles = [file];
          }

          if (evt.which === 3) {

            if (!$scope.isSelected(file)) {
              $scope.selectedFiles = [file];
            }

            var MAX_TOP_Y = 1000;
            var SAFE_TOP_Y = 500;
            // If there are too many documents in the list, and we click ones at the bottom
            //    evt.pageY is so high it makes the alert not appear in screen.
            //    (try deleting a file at the bottom of a very long list without sanitizing the value)
            $scope.lastY = evt.pageY > MAX_TOP_Y ? SAFE_TOP_Y : evt.pageY;
            // HACK: contextMenu.width() && .height() return 0 so use fixed sizes

            var contextMenuWidth = contextMenu.width() || 100;
            var contextMenuHeight = contextMenu.height || 200;
            if (evt.pageX >= window.innerWidth - contextMenuWidth) {
                evt.pageX -= contextMenuWidth;
            }
            if (evt.pageY >= window.innerHeight - contextMenuHeight) {
                evt.pageY -= contextMenuHeight;
            }

            contextMenu.hide().css({
              position: 'absolute',
              'z-index': 9999,
              left: evt.pageX,
              top: evt.pageY
            }).show();
          }

          if (evt.stopPropagation) evt.stopPropagation();
          if (evt.preventDefault) evt.preventDefault();
          evt.cancelBubble = true;
          evt.returnValue = false;
        };

        $scope.allKeepFiles = function() {
          return _.all($scope.files, function(f) { return f.name === '.keep'; });
        };

        $scope.notKeepFile = function(value, index, array) {
          return value.fd.name != '.keep';
        };

        $scope.delete = function (files) {
          var message = "Are you sure you want to delete";
          if (files.length === 1) {
            message += ' this file?';
          } else {
            message += ' these files?';
          }

          $scope.alertOptions = {
            show: true,
            title: 'Are you sure?',
            message: message,
            confirm: function() {
              $scope.alertOptions.show = false;
              files.forEach(function(f) {
                startLoading();
                filesystem.unlink(f.path)
                  .then(
                    function(res) {
                      stopLoading();
                      refreshFilter(res);
                    },
                    function(err) {
                      stopLoading();
                      if (err) {
                        $scope.alertOptions = {
                          show: true,
                          title: 'Error deleting file',
                          message: err,
                          hideButtons: true
                        };
                      }
                      console.log(err);
                    });
              });
              $scope.selectedFiles = [];
            }
          };
        };

        $scope.upload = function(files, litifyDoc) {
          var MAX_FILES_UPLOAD_AT_ONCE = 25;

          files = _.isArray(files) ? files : [files];

          if (!files.length) {
            return;
          }

          if (files.length > MAX_FILES_UPLOAD_AT_ONCE) {
            $scope.alertOptions = {
              show: true,
              title: 'Error Uploading Files',
              message: "Cannot upload more than " + MAX_FILES_UPLOAD_AT_ONCE + " files at once",
              hideButtons: true
            };
            return;
          }

          $scope.isUploading = ($scope.isUploading || 0) + files.length;
          $scope.progressbar.set(0);

          var fileProgress = _.map(files, function() { return 0; });

          var progressCb = function(evt) {
            if (!$scope.isUploading) {
              $scope.progressbar.complete();
              return;
            }

            var idx = _.indexOf(files, evt.file);
            fileProgress[idx] = (evt.loaded / evt.total) * 100;

            var totalProgress = _.reduce(fileProgress, function(memo, num) { return memo + num; });
            $scope.progressbar.set(totalProgress);
          };
          files.forEach(function(file) {
            var fileName = file.name;
            var path = $scope.currentPath
            if (path !== '/') {
              path += '/';
            }
            path += file.name;
            filesystem.writeFile(path, file, progressCb, litifyDoc).then(function(node) {
              $scope.isUploading--;
              refreshFilter();
              $scope.progressbar.complete();
            }, function(err) {
              if (err.data) {
                var title = "Unexpected error uploading " + file.name;
                if (err.data[0].errorCode === "STORAGE_LIMIT_EXCEEDED") {
                  title = "Storage Limit Exceeded";
                }
                else if (err.data[0].errorCode === "MAX_FILE_SIZE_EXCEEDED") {
                  title = "File Larger than 2GB";
                }
                else if (err.data[0].message.indexOf("Maximum size of request reached. Maximum size of request is 52428800 bytes.") != -1) {
                  title = "File larger than 39MB is reaching maximum request size";
                }
                $scope.alertOptions = {
                  show: true,
                  title: title,
                  message: err.data[0].errorMessage,
                  hideButtons: true
                };
              }
              console.log(err);
              $scope.isUploading--;
              $scope.progressbar.complete();
            });
          });
        };

        $scope.uploadNewVersion = function(file, litifyDoc) {
          if (!file || (_.isArray(file) && file.length > 1)) {
            return;
          }
          $scope.upload(file, litifyDoc);
        };

        $scope.showRenameFileDialog = function(f) {
          var filename = _.last(f.path.split('/'));
          if (filename.indexOf('.') > -1) {
            filename = _.initial(filename.split('.'));
          }

          $scope.renameFileContext = {
            filename: filename,
            extension: f.extension,
            file: f
          };
          $scope.showRenameFile = true;
        };

        $scope.renameFile = function(context) {
          var f = context.file;
          var renameFilename = context.filename;
          if (f.extension) {
            renameFilename += '.' + f.extension;
          }

          var parentPath = f.parent.path;
          if (parentPath[parentPath.length - 1] != '/') {
            parentPath = parentPath + '/';
          }

          startLoading();
          filesystem.rename(f.path, parentPath + renameFilename)
            .then(
              function(res) {
                stopLoading();
                refreshFilter(res);
              },
              function(err) {
                stopLoading();
                errorRenaming(err);
              });

          $scope.showRenameFile = false;
          $scope.selectedFiles = [];
        };

        $scope.areAllFiles = function(fs) {
          if (!(fs instanceof Array)) {
            fs = [fs];
          }

          return _.all(fs, function(f) { return f.type === 'file'; });
        };

        $scope.areAllFilesOrEmpty = function(fs) {
          if (!(fs instanceof Array)) {
            fs = [fs];
          }

          return _.all(fs, function(file) {
            if (file.type == 'file') {
              return true;
            }

            if (file.type === 'folder') {
              return _.all(file.children, function(f) {
                return f.name === '.keep';
              });
            }

            return false;
          });
        };

        $scope.filesWithProviderPath = function(fs) {
          if (!(fs instanceof Array)) {
            fs = [fs];
          }

          return _.all(fs, function(f) { return f.type === 'file' && f.litify_doc.litify_pm__ProviderPath__c; });
        };

        $scope.supportsVersions = function(fs) {
          if (!(fs instanceof Array)) {
            fs = [fs];
          }
          return documentsService.supportsVersions(fs[0]);
        };

        $scope.onClickContextMenu = function() {
           contextMenu.hide();
        };

        $scope.showCreateFolderDialog = function() {
          $scope.createFolderContext = {
            name: ''
          };
          $scope.showCreateFolder = true;
          setTimeout(function() {
            $('#create-folder-name').focus();
          }, 0);
        };

        $scope.createFolder = function(context) {
          var path = $scope.currentPath;
          if (path[path.length - 1] != '/') {
            path = path + '/';
          }
          path = path + $scope.createFolderContext.name;
          filesystem.mkdir(path).then(refreshFilter);
          $scope.showCreateFolder = false;
          newFolderForm = $scope["newFolderForm"];
          newFolderForm.$setUntouched();
          newFolderForm.$setPristine();
        };

        $scope.moveFileToParent = function(files) {
          files.forEach(function(f) {
            var parents_parent = f.parent.parent.path;

            if (parents_parent[parents_parent.length - 1] != '/') {
              parents_parent = parents_parent + '/';
            }

            startLoading();
            filesystem.rename(f.path, parents_parent + f.name)
              .then(
                function(res){
                  stopLoading();
                  refreshFilter(res);
                },
                function(err) {
                  stopLoading();
                  errorRenaming(err);
                });
          });
          $scope.selectedFiles = [];
        };

        function updateTags(file) {
          var doc = new sforce.SObject('litify_pm__LitifyDoc__c');
          doc.id = file.id;
          doc.litify_pm__Tags__c = file.tags.join(';');
          sforce.connection.update([doc], {
            onSuccess: function(data) {

            },
            onFailure: function(err) {
              console.log(err);
            }
          });
        }
        $scope.removeTag = function(file, tag) {
          file.tags = _.without(file.tags, tag);
          updateTags(file, $scope.previewFileContext);
        };

        $scope.addTag = function(tag) {
          var tagName = tag.title || tag.originalObject; // title if exists in picklist, originalObject otherwise
          var context = $scope.previewFileContext;
          if (context) {
            var tags = context.file.tags || [];
            tags.push(tagName);
            context.file.tags = _.uniq(tags);
            updateTags(context.file);
          }
        };

        $scope.searchTags = function(userInputString) {
          var deferred = $q.defer();
          sforce.connection.describeSObject('litify_pm__LitifyDoc__c', {
            onSuccess: function(data) {
              var field = _.findWhere(data.fields, { name: 'litify_pm__Tags__c' });
              var tags = field.picklistValues;
              if (Object.prototype.toString.call(tags) != '[object Array]') {
                tags = [tags];
              }

              tags = _.filter(tags, function(t) { return t.label.fuzzySearch(userInputString); });

              deferred.resolve(tags);
            },
            onFailure: deferred.reject
          });

          return deferred.promise;
        };

        function refreshFilter() {
          var promise;
          startLoading();
          var setFiles = function(results, files) {
            $scope.tableParams = new NgTableParams({
              count: results.length
            }, { counts: [], dataset: results });
            files = files || _.pluck(results, 'fd');
            $scope.files = files;
            stopLoading();
          };
          if ($scope.searchTerm && $scope.searchTerm.length > 0) {
            filesystem.search($scope.currentPath, $scope.searchTerm).then(setFiles);
          } else {
            filesystem.readdir($scope.currentPath).then(function(files) {
              files = _.toArray(files);
              var results = _.map(files, function(f) { return { fd: f, matches: null };});
              setFiles(results, files);
            });
          }
        }

        $scope.$watch('currentPath', function(newPath, oldPath) {
          navigationService.pathChanged(newPath, $scope.isSymlink);
          $scope.isSymlink = false;
          $scope.selectedFiles = [];
          refreshFilter();
        });

        $scope.$watch('searchTerm', function(newVal, oldVal) {
          if (oldVal != newVal) {
            refreshFilter();
          }
        });
      }
    };
  }]);

}(jQuery, window.litify));
