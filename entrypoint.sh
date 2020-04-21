#!/bin/bash -l

function printDelimeter {
  echo "----------------------------------------------------------------------"
}

function printLargeDelimeter {
  echo -e "\n\n------------------------------------------------------------------------------------------\n\n"
}

function printStepExecutionDelimeter {
  echo "----------------------------------------"
}

function displayInfo {
  echo
  printDelimeter
  echo
  HELM_CHECK_VERSION="v0.1.5"
  HELM_CHECK_SOURCES="https://github.com/chemistrygroup/helm-check-action"
  echo "Helm-Check $HELM_CHECK_VERSION"
  echo -e "Source code: $HELM_CHECK_SOURCES"
  echo
  printDelimeter
}


function helmDependencyUpdate {
  echo -e "\n"
  echo -e "1. Updating chart dependencies\n"
  if [ -z "$1" ]; then
    echo "Skipped due to condition: \$1 is not provided"
    return -1
  fi
  echo "helm dependency update $1"
  printStepExecutionDelimeter
  helm dependency update "$1"
  HELM_DEP_UPDATE_EXIT_CODE=$?
  printStepExecutionDelimeter
  if [ $HELM_DEP_UPDATE_EXIT_CODE -eq 0 ]; then
    echo "Result: SUCCESS"
  else
    echo "Result: FAILED"
  fi
  return $HELM_DEP_UPDATE_EXIT_CODE
}


function helmLint {
  echo -e "\n"
  echo -e "2. Checking a chart for possible issues\n"
  
  if [[ "$1" -eq 0 ]]; then
    if [ -z "$2" ]; then
      echo "Skipped due to condition: \$2 is not provided"
      return -1
    fi
    echo "helm lint $2"
    printStepExecutionDelimeter
    helm lint "$2"
    HELM_LINT_EXIT_CODE=$?
    printStepExecutionDelimeter
    if [ $HELM_LINT_EXIT_CODE -eq 0 ]; then
      echo "Result: SUCCESS"
    else
      echo "Result: FAILED"
    fi
    return $HELM_LINT_EXIT_CODE
  else
    echo "Skipped due to failure: Previous step has failed"
    return $1
  fi
}

function helmTemplate {
  printLargeDelimeter
  echo -e "3. Trying to render templates with provided values\n"
  if [[ "$1" -eq 0 ]]; then
    if [ -n "$3" ]; then
      echo "helm template --values $3 $2"
      printStepExecutionDelimeter
      helm template --values "$3" "$2"
      HELM_TEMPLATE_EXIT_CODE=$?
      printStepExecutionDelimeter
      if [ $HELM_TEMPLATE_EXIT_CODE -eq 0 ]; then
        echo "Result: SUCCESS"
      else
        echo "Result: FAILED"
      fi
      return $HELM_TEMPLATE_EXIT_CODE
    else
      printStepExecutionDelimeter
      echo "Skipped due to condition: \$CHART_VALUES is not provided"
      printStepExecutionDelimeter
    fi
  else
    echo "Skipped due to failure: Previous step has failed"
    return $1
  fi
  return 0
}

function totalInfo {
  printLargeDelimeter
  echo -e "Summary\n"
  if [[ "$1" -eq 0 ]]; then
    echo "Examination is completed; no errors found!"
    exit 0
  else
    echo "Examination is completed; errors found, check the log for details!"
    exit 1
  fi
}

function displayChartInfo {
  printDelimeter
  echo -e "Processing Chart $3"
  printDelimeter
  echo -e " Chart Location: $1"
  echo -e " Chart Values: $2"
  printDelimeter
}

counter=0
error=0



if [ -z "$CHART_LOCATION" ] && [ -z "$CHART_VALUES" ]; then 
  if [ -z "$CHART_DIRECTORY" ]; then 
    echo
    printDelimeter
    echo
    echo "You must Provide a CHART_LOCATION and a CHART_VALUES variables or
a CHART_DIRECTORY for multiple charts"
    echo
    printDelimeter
    echo
    exit 1
  else
    displayInfo
    for f in charts/*; do
        if [ -d "$f" ]; then
            displayChartInfo $f "$f/values.yaml" "$((counter+1))"
            helmDependencyUpdate $f
            helmLint $? $f
            returnval=$?
            helmTemplate $returnval $f "$f/values.yaml"
            if [ "$returnval" eq 1 ]; then 
                counter=counter+1
                error=1
            fi
        fi
    done 
  fi
else
  displayInfo
  helmDependencyUpdate $CHART_LOCATION
  helmLint $? $CHART_LOCATION
  helmTemplate $? $CHART_LOCATION
  error=$?
fi
totalInfo $error

