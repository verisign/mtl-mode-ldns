#!/bin/bash
APPDIR="../examples"

mtl_dnssec_keygen_sign_and_verify () {
    ALGORITHMS=$@
    echo ""
    rm -rf Kexample.com.*

    echo -e "\033[0;34mTesting Valid Keys\033[0m"
    echo " Generating Keys - $ALGORITHMS"
    for alg in $ALGORITHMS
    do
        $APPDIR/ldns-keygen -a $alg -b 2049 example.com >> /dev/null
        $APPDIR/ldns-keygen -k -a $alg example.com >> /dev/null
    done

    echo " Signing zone example.com" 
    KEYS=$(ls Kexample.com.*.key | sed 's/.key//g')

    $APPDIR/ldns-signzone -n example.com $KEYS   

    echo " Verifying zone example.com" 
    KEYS=$(ls Kexample.com.*.ds)

    FLAGS=""
    for k in $KEYS; do
        FLAGS="$FLAGS -k $k"
    done

    $APPDIR/ldns-verify-zone -V 3 example.com.signed $FLAGS
    if [ $? -eq 0 ]; then
       echo -e "\033[0;32mTest Passed\033[0m"
    else 
       echo -e "\033[0;31mTest Failed\033[0m"
       exit -1
    fi

    rm -rf Kexample.com.*
}

mtl_dnssec_test_mismatch_keys () {
    ALGORITHMS=$@
    echo ""
    rm -rf Kexample.com.*

    echo -e "\033[0;34mTesting Mismatched Keys\033[0m"
    echo " Generating Keys - $ALGORITHMS"
    for alg in $ALGORITHMS
    do
        $APPDIR/ldns-keygen -a $alg -b 2049 example.com >> /dev/null
        $APPDIR/ldns-keygen -k -a $alg example.com >> /dev/null
    done

    echo " Verifying zone example.com" 
    KEYS=$(ls Kexample.com.*.ds)

    FLAGS=""
    for k in $KEYS; do
        FLAGS="$FLAGS -k $k"
    done

    $APPDIR/ldns-verify-zone -V 3 example.com.signed $FLAGS   
    if [ $? -ne 0 ]; then
       echo -e "\033[0;32mTest Passed\033[0m"
    else 
       echo -e "\033[0;31mTest Failed\033[0m"
       exit -1
    fi

    rm -rf Kexample.com.*
}


mtl_dnssec_test_missing_soa_sig () {
    ALGORITHMS=$@
    echo ""
    rm -rf Kexample.com.*

    echo -e "\033[0;34mTesting Missing SOA Signature\033[0m"
    echo " Generating Keys - $ALGORITHMS"
    for alg in $ALGORITHMS
    do
        $APPDIR/ldns-keygen -a $alg -b 2049 example.com >> /dev/null
        $APPDIR/ldns-keygen -k -a $alg example.com >> /dev/null
    done

    echo " Signing zone example.com" 
    KEYS=$(ls Kexample.com.*.key | sed 's/.key//g')

    $APPDIR/ldns-signzone -n example.com $KEYS   

    # Remove the SOA signature
    sed -i '/IN	RRSIG	SOA/d' ./example.com.signed

    echo " Verifying zone example.com" 
    KEYS=$(ls Kexample.com.*.ds)

    FLAGS=""
    for k in $KEYS; do
        FLAGS="$FLAGS -k $k"
    done

    $APPDIR/ldns-verify-zone -V 3 example.com.signed $FLAGS
    if [ $? -ne 0 ]; then
       echo -e "\033[0;32mTest Passed\033[0m"
    else 
       echo -e "\033[0;31mTest Failed\033[0m"
       exit -1
    fi

    rm -rf Kexample.com.*
}


mtl_dnssec_test_soa_incorrect () {
    ALGORITHMS=$@
    echo ""
    rm -rf Kexample.com.*

    echo -e "\033[0;34mTesting Invalid SOA Signature\033[0m"
    echo " Generating Keys - $ALGORITHMS"
    for alg in $ALGORITHMS
    do
        $APPDIR/ldns-keygen -a $alg -b 2049 example.com >> /dev/null
        $APPDIR/ldns-keygen -k -a $alg example.com >> /dev/null
    done

    echo " Signing zone example.com" 
    KEYS=$(ls Kexample.com.*.key | sed 's/.key//g')

    $APPDIR/ldns-signzone -n example.com $KEYS   

    # Replace the SOA signature with the one for the AAAA record
    # Which is a valid condensed signature but won't verify with this message
    SOA_RRSIG=$(grep 'IN	RRSIG	SOA' ./example.com.signed | awk '{$NF=""; print $0}')
    sed -i '/IN	RRSIG	SOA/d' ./example.com.signed    
    AAAA_RRSIG=$(grep 'IN	RRSIG	AAAA' ./example.com.signed | awk 'NF>1{print $NF}')
    echo $SOA_RRSIG $AAAA_RRSIG >> ./example.com.signed

    echo " Verifying zone example.com" 
    KEYS=$(ls Kexample.com.*.ds)

    FLAGS=""
    for k in $KEYS; do
        FLAGS="$FLAGS -k $k"
    done

    $APPDIR/ldns-verify-zone -V 3 example.com.signed $FLAGS
    if [ $? -ne 0 ]; then
       echo -e "\033[0;32mTest Passed\033[0m"
    else 
       echo -e "\033[0;31mTest Failed\033[0m"
       exit -1
    fi

    rm -rf Kexample.com.*
}

test_scheme() {
    SCHEMES=$@

    echo "Key List = $SCHEMES"
    mtl_dnssec_keygen_sign_and_verify $SCHEMES
    mtl_dnssec_test_mismatch_keys $SCHEMES
    mtl_dnssec_test_missing_soa_sig $SCHEMES
    mtl_dnssec_test_soa_incorrect $SCHEMES
}

clear

declare -a curr_schemes=(ECDSAP256SHA256)
declare -a mtl_schemes=(
    Falcon-padded-512-MTL-SHAKE-128
    ML-DSA-44-MTL-SHAKE-128
    SLH-DSA-SHA2-128s-MTL-SHA2-128
    SLH-DSA-SHAKE-128s-MTL-SHAKE-128
    MAYO-1-MTL-SHAKE-128
    MAYO-2-MTL-SHAKE-128
    SNOVA_24_5_4-MTL-SHAKE-128
)
declare -a pqc_schemes=(
    FL_DSA_512
    ML_DSA_44
    MAYO-1
    MAYO-2
    SLH_DSA_SHA2_128s
    SLH_DSA_SHAKE_128s
    SNOVA_24_5_4
#   Hawk-512
#    SQIsign_lvl1
)

concatenated_scheme=""
for i in "${curr_schemes[@]}"
do
    concatenated_scheme="${concatenated_scheme} ${i}"
    test_scheme $i
done
echo "Key List = $concatenated_scheme"
test_scheme $concatenated_scheme

concatenated_scheme=""
for i in "${mtl_schemes[@]}"
do
    concatenated_scheme="${concatenated_scheme} ${i}"
    test_scheme $i
done
echo "Key List = $concatenated_scheme"
test_scheme $concatenated_scheme


concatenated_scheme=""
for i in "${pqc_schemes[@]}"
do
    concatenated_scheme="${concatenated_scheme} ${i}"
    test_scheme $i
done
echo "Key List = $concatenated_scheme"
test_scheme $concatenated_scheme


echo ""
echo -e "\033[0;32mTesting is complete - All Tests Pass!\033[0m"
exit 0