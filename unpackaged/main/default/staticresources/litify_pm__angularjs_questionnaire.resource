var cqcApp = angular.module('questionnaireApp', ['localytics.directives', 'litify']);

cqcApp.controller('questionnaireController', ['$scope', function($scope) {
	$scope.strQuestions = jQuery("textarea[id$=':questions']").val();
	try { 
		$scope.questions = JSON.parse($scope.strQuestions); 
	} catch(err) {
		$scope.questions = {
			first_question_node: null,
			question_nodes: {}
		};
	}

	$scope.quest_name = jQuery("input[id$=':questionnairename']").val();
	$scope.navigationRules = {};
	$scope.nodeNameUpdateIndex = null;
	$scope.selectedNode = null;
	$scope.setTitleAttribute = function(evt) {
		var activeResultsWithinTarget = jQuery(evt.currentTarget).find('.active-result');
		if (activeResultsWithinTarget) {
			if (activeResultsWithinTarget[0] && !activeResultsWithinTarget[0].title) {
				activeResultsWithinTarget.each(function(_, e) {
					e.title = e.innerText;
				});
			}
		}
	};

	$scope.updateNode = function(nodeProps) {
		var key;
		if (!nodeProps.description) {
			for (var i = 0; i < Object.keys($scope.questions.question_nodes).length; i++) {
				key = Object.keys($scope.questions.question_nodes)[i];
				if($scope.questions.question_nodes[key].name == nodeProps.name) {
					var nodeNumber = i + 1;
					nodeProps.description = 'Node ' + nodeNumber;
				}
			}
		}
		$scope.refreshJson();
	};

	$scope.refreshJson = function() {
		// we pull off modifications from the questions
		var questions = $scope.questions;
		var modifications = _.map($scope.modificationsObject, function(mod, key) {
			var prop = _.find($scope.objectPropertyOptions, function(o) { return o.field_name == mod; });

			var sobject_name = 'litify_pm__Intake__c';
			return { question_id: key, sobject_name: sobject_name, field_name: mod };
		});

		modifications = _.reject(modifications, function(mod) {
			return !mod.question_id || !mod.field_name;
		});


		$scope.strQuestions = angular.toJson(questions);
		$scope.strModifications = angular.toJson(modifications);
	};

	//the porpouse of this method is to clean the mapping when a question have one and the user change (no delete) this question
	$scope.refreshSobjectLookup = function(newId, oldId) {
		if(   oldId && newId &&
					newId != oldId &&
					$scope.strQuestions &&
					!$scope.strQuestions.includes('"question_id":"' + oldId + '"')) {
			deleteMaping(oldId);      
			$scope.refreshJson();      
		}    
	}

	var refreshLocalNodes = function() {
		if ($scope.questionnaireId) {
			$scope.allQuestionnaireNodes = _.reject($scope.allQuestionnaireNodes, function(node) {
				return node.questionnaire_id == $scope.questionnaireId;
			});
		} else {
			$scope.allQuestionnaireNodes = _.reject($scope.allQuestionnaireNodes, function(node) {
				return !node.questionnaire_id;
			});
		}

		var localNodes = _.map($scope.questions.question_nodes, function(node, key) {
			return {
				questionnaire_id: $scope.questionnaireId,
				node_id: key,
				node_name: node.name,
				node: node
			};
		});

		$scope.allQuestionnaireNodes = $scope.allQuestionnaireNodes.concat(localNodes);
	};

	$scope.refreshQuestions = function() {
		$scope.selectedNode.questions = _.map($scope.selectedNode.questions, function(value){
			var currentQuestion = _.findWhere($scope.allQuestions, {Id: value.question_id});
			
			//to load mapping if have one
			var sobjectModificationLabel = '';
			if ($scope.modificationsObject && $scope.modificationsObject[value.question_id]) {
				var fieldValue = '!FIELD_VALUE(' + $scope.modificationsObject[value.question_id] + ')';
				var sobjectModificationObject = _.findWhere($scope.objectPropertyOptions, {value: fieldValue});
				sobjectModificationLabel = sobjectModificationObject ? sobjectModificationObject.label : '';
			}

			if (value.label == currentQuestion.Label && value.sobjectModification == sobjectModificationLabel) {
				return value;
			} else {
				return {
					question_id: value.question_id,
					required: value.required,
					description: value.description,
					label: currentQuestion ? currentQuestion.Label : '',
					sobjectModification: sobjectModificationLabel
				}
			}
		});
	}

	$scope.selectNode = function(node) {
		$scope.selectedNode = node;
	//node.cqc_node = node.cqc_node || {};
		$scope.refreshQuestions(); 
	};

	$scope.deleteNode = function(nodeId, nodeToDelete) {
		if (!$scope.questions.question_nodes) {
			return;
		}

		// Delete all mappings of the deleted question on node
		if(nodeToDelete && nodeToDelete.questions && nodeToDelete.questions.length > 0){
			var questionLength = nodeToDelete.questions.length;
			for (var i = 0; i < questionLength; i++) {
				deleteMaping(nodeToDelete.questions[i].question_id);
			}
		}

		$scope.questions.question_nodes = _.omit($scope.questions.question_nodes, function(node) {
			return node == nodeToDelete;
		});

		if ($scope.questions.first_question_node == nodeId) {
			$scope.questions.first_question_node = Object.keys($scope.questions.question_nodes)[0];
		}

		$scope.refreshJson();
		refreshLocalNodes();
	};

	$scope.addNode = function() {
		var question_nodes = $scope.questions.question_nodes;

		var new_node = {name: 'node ' + (Object.keys(question_nodes).length + 1), description: 'Node ' + (Object.keys(question_nodes).length + 1), check_cqc: false, questions: []};

		var node_id = '';
		for (var i = 0; i < 12; i++) {
			node_id += Math.floor(Math.random() * 15).toString(16);
		}

		question_nodes[node_id] = new_node;

		if (Object.keys(question_nodes).length == 1) {
			$scope.questions.first_question_node = node_id;
		}

		$scope.refreshJson();
		refreshLocalNodes();
	};

	$scope.addQuestionToNode = function(node) {
		node.questions = node.questions || [];
		node.questions.push({});
		$scope.refreshJson();
	};

	$scope.deleteQuestionFromNode = function (node, question) {
		node.questions = _.reject(node.questions, function(q) {
			return q === question;
		});

		deleteMaping(question.question_id);

		$scope.refreshJson();
	};

	deleteMaping = function(questionId){
		console.log("Deleting mapping :" + questionId);
			// delete the mapping related with the question to delete
		var modifications = _.map($scope.modificationsObject, function(mod, key) { 
			var sobject_name = 'litify_pm__Intake__c';
			return { question_id: key, sobject_name: sobject_name, field_name: mod };
		});

		modifications = _.reject(modifications, function(mod) {
			return mod.question_id === questionId;
		});

		//REFACTOR THIS LINE  hippy implementation
		$scope.modifications = JSON.parse(JSON.stringify(modifications));    
		$scope.modificationsObject = _.reduce($scope.modifications, function(memo, mod) {
			memo[mod.question_id] = mod.field_name;
			return memo;
		}, {});  

	}

	$scope.canUseOR = function(inputType, operator) {    
    if (operator && inputType) {
      return _.contains(['equals', 'not_equals'], operator.toLowerCase()) && 
        _.contains(['string', 'textarea', 'email', 'phone', 'decimal', 'integer', 'url', 'currency'], inputType.toLowerCase());
    } else return false;
  }

	$scope.addRuleToNode = function(node) {
		node.rules = node.rules || [];
		node.rules.push({questionnaire_id: null, next_question_node_id: null, criterias: []});
	};
	$scope.deleteRuleFromNode = function(node, rule) {
		node.rules = _.reject(node.rules, function(r) {
			return r === rule;
		});
		$scope.refreshJson();
	};
	$scope.addNavToRule = function(rule) {
		rule.criterias = rule.criterias;
		rule.criterias.push({value_1: null, value_2: null, operator: null});
		$scope.refreshJson();
	};

	$scope.refreshCriterion = function(crit) {
		var value_1_obj = crit.value_1_obj || {};
		var value_2_obj = crit.value_2_obj || [];
		var formula_obj = crit.formula_obj || {};

		if (value_1_obj.type == 'reference' && value_1_obj.hash && !value_1_obj.referenced_object_name) {
			// lookup the referenced object type
			sforce.connection.query("SELECT litify_pm__Lookup_Sobject_Type__c FROM litify_pm__Question__c WHERE ID = '" + value_1_obj.hash + "'", {
				onSuccess: function(result) {
					value_1_obj.referenced_object_name = result.records["litify_pm__Lookup_Sobject_Type__c"];
				},
				onFailure: function(err) {
					console.log(err);
				}
			});
		}

		crit.value_1 = value_1_obj.value;
		// crit.value_1_label = value_1_obj.label;

		var value_2_array;
		//if not array create one
		if (!Array.isArray(crit.value_2_obj) ) {
			value_2_array = [];
			//if there is value put it on the array
			if(crit.value_2_obj) {
				value_2_array.push(value_2_obj);
			}			
		} else {
			value_2_array = value_2_obj;
		}		

		if (value_1_obj.type === 'multiselect') {
			value_2_array = [];
			multiSelectValue2 = _.reduce(crit.multi_select_options || [], function(memo, str) {
			return memo + ';' + str; 
			});
			value_2_array.push(multiSelectValue2);
		}
		
		var value_2_typed = [];

		_.each(value_2_array, function(value2) {

			var formulaName = value_1_obj.type;
			
			if (crit.formula_obj) {
				formulaName = formula_obj.value;
			}

			value_2_typed.push('!' + (formulaName || '').toUpperCase() + '(' + value2 + ')');

		});

		crit.value_2 = value_2_typed;

		$scope.refreshJson();
	};

	// initialize link between textboxes and json
	(function initJson() {
		// we put modifications onto the questions object
		$scope.strModifications = jQuery("textarea[id$=':modifications']").val();
		try { 
			$scope.modifications = JSON.parse($scope.strModifications);
		} catch(err) {
			$scope.modifications = [];
		}
		$scope.modificationsObject = _.reduce($scope.modifications, function(memo, mod) {
			memo[mod.question_id] = mod.field_name ? mod.field_name.toLowerCase() : '';
			return memo;
		}, {});

		//console.log("$scope.modificationsObject", $scope.modificationsObject);

		$scope.allQuestions = JSON.parse(jQuery("#allQuestions").val());
		var objectProperties = JSON.parse(jQuery('#objectProperties').val());

		$scope.objectPropertyOptions = _.map(objectProperties, function(o) {

			var fieldLabel = '[' + o.object_name + '] ' + o.field_label;

			if (o.relationship_name) {
				fieldLabel = '[' + o.relationship_name + '] ' + o.field_label;
			}

			var field_type;
			switch(o.field_type.toLowerCase) {
				case 'double':
					field_type = 'decimal';
				break;
				case 'multipicklist':
					field_type = 'multiselect';
				break;
				case 'picklist':
					field_type = 'select';
				break;
				case 'encryptedstring':
					field_type = 'text_encrypted';
				break;
				default:
					field_type = 'string';
				break;
			}

			var field_name = o.field_name;
			if (o.relationship_name) {
				field_name = o.relationship_name + '.' + field_name;
			}

			return {
				hash: o.object_name + '.' + o.field_name,
				label: fieldLabel,
				field_name: field_name,
				type: field_type
			};
		});
		$scope.objectPropertyOptions.splice(0, 0, {hash: '', label: ''});

		$scope.questionnaireId = jQuery('#questionnaireId').text();

		$scope.allQuestionnaireNames = _.chain(JSON.parse(jQuery('#allQuestionnaires').val()))
			.map(function(quest, key) {
				return { id: quest.Id, name: quest.Name };
			})
			.value();
		//console.log($scope.allQuestionnaireNames);
		$scope.allQuestionnaireNames.splice(0, 0, {id: '', name: ''});

		$scope.allQuestionnaireNodes = _.chain(JSON.parse(jQuery('#allQuestionnaires').val()))
			.map(function(quest, key) {
				var questions = {};
				try {
					questions = JSON.parse(quest.Questions || '');
				} catch (e) {
					questions = {};
				}
				// questions.question_nodes = questions.question_nodes || [];

				return _.map(questions.question_nodes, function(node, key) {
					return {
						questionnaire_id: quest.Id,
						node_id: key,
						node_name: node.name,
						node: node
					};
				});
			})
			.flatten()
			.value();
		$scope.allQuestionnaireNodes.splice(0, 0, {questionnaire_id: '', node_id: '', node_name: ''});

			refreshLocalNodes();
	}());

	(function populateDropdowns() {
		var objectProperties = JSON.parse(jQuery("#objectProperties").val());
		$scope.allQuestions = JSON.parse(jQuery("#allQuestions").val());

		var mpForQ = {};

		_.each($scope.allQuestions, function(q) {
			mpForQ[q.Id] = _.map(objectProperties, function(o) {
				var fieldName;
				var fieldLabel;

				var field_type_question;
				switch(o.field_type.toLowerCase()) {
					case 'double':            
						field_type_question = 'decimal';
						break;
					case 'multipicklist':
						field_type_question = 'multiselect';
						break;
					case 'picklist':
						field_type_question = 'select';
						break;
					case 'reference':
						field_type_question = 'lookup';
						break;
					case 'encryptedstring':
						field_type_question = 'text_encrypted';
						break;
					default:
						field_type_question = o.field_type.toLowerCase();
						break;
				}

				var field_type;
				switch(o.field_type.toLowerCase()) {
					case 'double':
						field_type = 'decimal';
						break;
					case 'multipicklist':
						field_type = 'multiselect';
						break;
					case 'picklist':
						field_type = 'select';
						break;
					case 'encryptedstring':
						field_type = 'text_encrypted';
					break;
					default:
						field_type = 'string';
						break;
				}
        
        var isFormulaField = o.isFormulaField;
        
				// We need to treat both integer and doubles as numeric fields
				var answer_type = q.AnswerType.toLowerCase() == 'integer' ? 'decimal' : q.AnswerType.toLowerCase();

				if (answer_type == field_type_question && !isFormulaField) {
					if (field_type_question == 'lookup') {
						if (q.SObjectType.toLowerCase() != o.referenced_object_name.toLowerCase()) {
							return {
								label: 'undefined',
								value: 'undefined',
								type: 'undefined',
								field_name: 'undefined',
								options: []
							};
						}
					}
					if (o.relationship_name) {
						fieldLabel = '[' + o.relationship_name + '].' + o.field_label;
						fieldName = o.relationship_name + '.' + o.field_name;
					} else {
						fieldLabel = '[' + o.object_name + '].' + o.field_label;
						fieldName = o.field_name;
					}
					
					return {
						label: fieldLabel,
						value: '!FIELD_VALUE(' + fieldName + ')',
						type: field_type,
						field_name: fieldName.toLowerCase(),
						options: o.field_options
					};
				}
				else {
					return {
						label: 'undefined',
						value: 'undefined',
						type: 'undefined',
						field_name: 'undefined',
						options: []
					};
				}
			});

			//console.log(" mapppppp`pp ",mpForQ );


			//console.log("mpForQ[q.Id]: " + mpForQ[q.Id]);        
			mpForQ[q.Id] = _.reject(mpForQ[q.Id], function(m) {
				return m.label == 'undefined';
			});     
			//console.log("after filter mpForQ[q.Id]: " + mpForQ[q.Id]);

		});

		$scope.questionMappings = mpForQ;


	 
		$scope.objectPropertyOptions = _.map(objectProperties, function(o) {
			var fieldName;
			var fieldLabel;
			if (o.relationship_name) {
				fieldLabel = '[' + o.relationship_name + '].' + o.field_label;
				fieldName = o.relationship_name + '.' + o.field_name;
			} else {
				fieldLabel = '[' + o.object_name + '].' + o.field_label;
				fieldName = o.field_name;
			}

			//console.log(fieldName);

			var field_type;
			switch(o.field_type.toLowerCase()) {
				case 'double':
				field_type = 'decimal';
				break;
				case 'multipicklist':
				field_type = 'multiselect';
				break;
				case 'picklist':
				field_type = 'select';
				break;
				case 'encryptedstring':
				field_type = 'text_encrypted';
				break;
				default:
				field_type = 'string';
				break;
			}

			return {
				label: fieldLabel,
				value: '!FIELD_VALUE(' + fieldName + ')',
				type: field_type,
				options: o.field_options
			};
		});
	}());

	(function refreshValueObjects() {
		_.each($scope.questions.question_nodes || [], function(val) {
			_.each(val.rules || [], function(rule) {
				_.each(rule.criterias || [], function(crit) {

					var formula_regexp = /\!([a-z\_]+)\((.+)\)/gi;
					if (crit.value_1 && !crit.value_1_obj) {
						var value_1 = formula_regexp.exec(crit.value_1);
						switch(value_1[1].toLowerCase()) {
							case 'question_id':
								var selectedQuestion = _.findWhere($scope.allQuestions, { Id: value_1[2] });
								if (selectedQuestion) {
									var options = JSON.parse(selectedQuestion.AnswerOptions);
									options = _.map(options, function(val) {
										return {
											label: val,
											value: val
										};
									});
									crit.value_1_obj = {
										value: crit.value_1,
										label: selectedQuestion.Label,
										type: selectedQuestion.AnswerType.toLowerCase(),
										options: options
									};
								}
							break;
							case 'field_value':
								var fieldValue = '!FIELD_VALUE(' + value_1[2] + ')';
								var selectedProperty = _.findWhere($scope.objectPropertyOptions, { value: fieldValue });
								crit.value_1_obj = selectedProperty;
								crit.value_1_obj.value = fieldValue;
							break;
						}
					}

					if (!crit.value_2_obj) {
						var value_2 = crit.value_2;
						formula_regexp = /\!([a-z\_]+)\((.+)\)/gi;
						value_2 = formula_regexp.exec(value_2);
						if (value_2) {
							crit.value_2_obj = value_2[2];
						}
					}
				});
			});
		});
	}());
}]);