#!/bin/bash
#*********************************************************************************************#
#   FileName     [ 3_abalone.sh ]
#   Synopsis     [ script that runs Libsvm on the Abalone dataset ]
#   Author       [ Ting-Wei Liu (Andi611) ]
#   Copyright    [ Copyleft(c), NTUEE, NTU, Taiwan ]
#*********************************************************************************************#


#---arguments---#
LIBSVM_PATH=${1:-/home/andi611/LibSVM-Classification/libsvm-3.23}
TRAIN_DATA_PATH=${2:-../data/abalone/abalone_train.csv}
TEST_DATA_PATH=${3:-../data/abalone/abalone_test.csv}
OUTPUT_FILE_PATH=${4:-../result/abalone_predict.csv}


#---variables---#
MODEL_NAME=model_abalone.libsvm
PROCESSED_TRAIN_DATA=abalone.tr
PROCESSED_TEST_DATA=abalone.te
MODE=RUN_BEST
#MODE=COMPARE_KERNAL
#MODE=COMPARE_CSVM
#MODE=COMPARE_SCALE
#MODE=RUN_ALL

python3 data_loader.py --data_abalone --train_path_abalone ${TRAIN_DATA_PATH} --test_path_abalone ${TEST_DATA_PATH} \
					   --output_train_path_abalone ${PROCESSED_TRAIN_DATA} --output_test_path_abalone ${PROCESSED_TEST_DATA}


#---run best---#
if [ "${MODE}" = RUN_BEST ] || [ "${MODE}" = RUN_ALL ] ; then
	echo
	echo "|------------------------------------------|"
	echo "|------ Running with Best Parameters ------|"
	echo "|------------------------------------------|"

	$LIBSVM_PATH/svm-train -s 0 -t 0 -e 0.01 -c 20 ${PROCESSED_TRAIN_DATA} ${MODEL_NAME}
	echo "Training:"
	$LIBSVM_PATH/svm-predict ${PROCESSED_TRAIN_DATA} ${MODEL_NAME} ${OUTPUT_FILE_PATH}.train
	rm ${OUTPUT_FILE_PATH}.train 
	echo "Testing:"
	$LIBSVM_PATH/svm-predict ${PROCESSED_TEST_DATA} ${MODEL_NAME} ${OUTPUT_FILE_PATH}
fi

if [ "${MODE}" = COMPARE_KERNAL ] || [ "${MODE}" = RUN_ALL ] ; then
	echo
	echo "|--------------------------------------------------|"
	echo "|------ Comparing Different Kernal Functions ------|"
	echo "|--------------------------------------------------|"

	kernals=( linear polynomial radial_basis sigmoid precomputed_kernal )
	for ((idx=0; idx<${#kernals[@]}; ++idx));
	do
		echo
		echo ">>> Kernal function: ${kernals[idx]}"
		$LIBSVM_PATH/svm-train -s 0 -t ${idx} -e 0.01 -c 20 -q ${PROCESSED_TRAIN_DATA} ${MODEL_NAME}.temp
		$LIBSVM_PATH/svm-predict ${PROCESSED_TEST_DATA} ${MODEL_NAME}.temp ${OUTPUT_FILE_PATH}
		rm ${OUTPUT_FILE_PATH} ${MODEL_NAME}.temp
	done
fi

if [ "${MODE}" = COMPARE_CSVM ] || [ "${MODE}" = RUN_ALL ] ; then
	echo
	echo "|-------------------------------------------------------|"
	echo "|------ Comparing Different Linear C-SVM Settings ------|"
	echo "|-------------------------------------------------------|"

	epsilons=( 0.00001 0.0001 0.001 0.01 0.1 1.0 2.0 3.0 4.0 10.0 )
	for ((idx=0; idx<${#epsilons[@]}; ++idx));
	do
		echo
		echo ">>> epsilon value: ${epsilons[idx]}"
		$LIBSVM_PATH/svm-train -s 0 -t 0 -e ${epsilons[idx]} -q ${PROCESSED_TRAIN_DATA} ${MODEL_NAME}.temp
		$LIBSVM_PATH/svm-predict ${PROCESSED_TEST_DATA} ${MODEL_NAME}.temp ${OUTPUT_FILE_PATH}
		rm ${OUTPUT_FILE_PATH} ${MODEL_NAME}.temp
	done

	cs=( 1 10 20 30 40 50 60 )
	for ((idx=0; idx<${#cs[@]}; ++idx));
	do
		echo
		echo ">>> C values: ${cs[idx]}"
		$LIBSVM_PATH/svm-train -s 0 -t 0 -e 0.01 -c ${cs[idx]} -q ${PROCESSED_TRAIN_DATA} ${MODEL_NAME}.temp
		$LIBSVM_PATH/svm-predict ${PROCESSED_TEST_DATA} ${MODEL_NAME}.temp ${OUTPUT_FILE_PATH}
		rm ${OUTPUT_FILE_PATH} ${MODEL_NAME}.temp
	done
fi

if [ "${MODE}" = COMPARE_SCALE ] || [ "${MODE}" = RUN_ALL ] ; then
	echo
	echo "|---------------------------------------------------------------|"
	echo "|------ Comparing Different Kernal Functions with Scaling ------|"
	echo "|---------------------------------------------------------------|"

	kernals=( linear polynomial radial_basis sigmoid precomputed_kernal )
	for ((idx=0; idx<${#kernals[@]}; ++idx));
	do
		echo
		echo ">>> Kernal function: ${kernals[idx]}"
		$LIBSVM_PATH/svm-scale -l 0 -u 1 ${PROCESSED_TRAIN_DATA} > ${PROCESSED_TRAIN_DATA}.scale
		$LIBSVM_PATH/svm-scale -l 0 -u 1 ${PROCESSED_TEST_DATA} > ${PROCESSED_TEST_DATA}.scale
		$LIBSVM_PATH/svm-train -s 0 -t ${idx} -e 0.01 -c 20 -q ${PROCESSED_TRAIN_DATA}.scale ${MODEL_NAME}.temp
		$LIBSVM_PATH/svm-predict ${PROCESSED_TEST_DATA}.scale ${MODEL_NAME}.temp ${OUTPUT_FILE_PATH}
		rm ${PROCESSED_TRAIN_DATA}.scale ${PROCESSED_TEST_DATA}.scale ${OUTPUT_FILE_PATH} ${MODEL_NAME}.temp
	done
fi

rm ${PROCESSED_TRAIN_DATA} ${PROCESSED_TEST_DATA}
echo
echo "Done!"

