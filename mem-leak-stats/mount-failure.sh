#!/bin/sh
#
# Try to access a file on a Gluster volume that can not be reached due to
# incorrect hostname.
#

VERSION="$(rpm -q glusterfs-api --qf '%{VERSION}-%{RELEASE}\n')"
LOG="$(basename $0 .sh)_${VERSION}.log"
STATS="$(basename $0 .sh).csv"

TEST='qemu-img info gluster://nohost.example.invalid/nonexistent/missing.img'
VALGRIND="valgrind --leak-check=full --errors-for-leak-kinds=all --log-file=${LOG}"

${VALGRIND} ${TEST} 2>/dev/null


# to parse output
#
# ==17050== LEAK SUMMARY:
# ==17050==    definitely lost: 1,012 bytes in 5 blocks
# ==17050==    indirectly lost: 7,772 bytes in 26 blocks
# ==17050==      possibly lost: 272,712 bytes in 32 blocks
# ==17050==    still reachable: 171,434 bytes in 971 blocks
# ==17050==         suppressed: 0 bytes in 0 blocks
# ==17050== Reachable blocks (those to which a pointer was found) are not shown.
# ==17050== To see them, rerun with: --leak-check=full --show-leak-kinds=all
# ==17050== 
# ==17050== For counts of detected and suppressed errors, rerun with: -v
# ==17050== ERROR SUMMARY: 166 errors from 166 contexts (suppressed: 0 from 0)
#

strip_comma() {
	sed 's/,//'
}

DEF_LOST_CNT=$(awk '/definitely lost:/ {print $4}' ${LOG} | strip_comma)
DEF_LOST_BLK=$(awk '/definitely lost:/ {print $7}' ${LOG} | strip_comma)
IND_LOST_CNT=$(awk '/indirectly lost:/ {print $4}' ${LOG} | strip_comma)
IND_LOST_BLK=$(awk '/indirectly lost:/ {print $7}' ${LOG} | strip_comma)
POS_LOST_CNT=$(awk '/possibly lost:/ {print $4}' ${LOG} | strip_comma)
POS_LOST_BLK=$(awk '/possibly lost:/ {print $7}' ${LOG} | strip_comma)
REACHABLE_CNT=$(awk '/still reachable:/ {print $4}' ${LOG} | strip_comma)
REACHABLE_BLK=$(awk '/still reachable:/ {print $7}' ${LOG} | strip_comma)
ERRORS=$(awk '/ERROR SUMMARY:/ {print $4}' ${LOG} | strip_comma)

# add a header only if the file does not exist
if [ ! -e "${STATS}" ]
then
	echo 'Version,errors,definitely lost (bytes),definitely lost (blocks),indirectly lost (bytes),indirectly lost (blocks),possibly lost (bytes),possibly lost (blocks),still reachable (bytes),still reachable (blocks)' > ${STATS}
fi

echo "${VERSION},${ERRORS},${DEF_LOST_CNT},${DEF_LOST_BLK},${IND_LOST_CNT},${IND_LOST_BLK},${POS_LOST_CNT},${POS_LOST_BLK},${REACHABLE_CNT},${REACHABLE_BLK}" >> ${STATS}

echo "Statistics for version ${VERSION} have been added to ${STATS}"
