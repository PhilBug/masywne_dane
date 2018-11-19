#!/usr/bin/env bash
 
# unique_tracks.txt — identyfikator utworu, identyfikator wykonania, nazwa artysty, tytuł utworu
# TRWDFHK128F92D676B<SEP>SOFXPQS12AAF3B47EA<SEP>Thelonious Monk<SEP>Evonce
 
# triplets_sample_20p.txt — identyfikator użytkownika, identyfikator utworu, data odsłuchania
# e8d37d9337aec9dfa73c47fdf04b3f18780ac251<SEP>SOMQMFR12A8C137B1F<SEP>1018012325
 
# Schemat:
# Odsłuchanie - id_odsluchania, id_uzytkownika, data, id_utworu
# Data - rok, miesiac, dzien, id_daty
# Utwór - id_utworu, nazwa_artysty, tytuł_utoworu

# id, id uzytkownika, id utworu, timestamp
function odsluchania() {
    echo "creating odsluchania.txt..."
    mawk -F '<SEP>' '{
        a++;
        printf("%s,%s,%s,%s\n", a, $1, $2, $3);
    }' triplets_sample_20p.txt > odsluchania.txt
    echo "creating odsluchania.txt... done!"
}

# id, rok, miesiac, dzien
function data() {
    echo "creating data.txt..."
    gawk -F '<SEP>' '{
        year = strftime("%y", $3);
        month = strftime("%m", $3);
        day = strftime("%d", $3);
        printf("%s,%s,%s,%s\n", $3, year, month, day);
    }' triplets_sample_20p.txt > data.tmp
    sort -S 16G --parallel=6 -nr -k1 data.tmp > data.txt
    echo "creating data.txt... done!"
    rm data.tmp
}

# id utworu, id wykonania, nazwa artysty, tytul
function utwor() {
    echo "creating utwor.txt..."
    sed 's:<SEP>:,:g' unique_tracks.txt | sort -S 16G --parallel=6 -u -t',' -k2 > utwor.txt
    echo "creating utwor.txt... done!"
}

function create() {
    START=$(date +%s.%N)
    
    odsluchania
    data
    utwor
    
    END=$(date +%s.%N)
    echo -n "time elapsed: "
    echo "$END - $START" | bc

}

function query2() {
    sort -S 16G --parallel=6 -u -k2,3 -t ',' odsluchania.txt | cut -f2 -d ',' | uniq -c | sort -S 16G --parallel=6 -k1 -t ',' -nr | head -n 10 | mawk '{
        printf("%s %s\n", $2, $1)
     }'
}

function query3() {
    sort -S 16G --parallel=6 -k3 -t ',' odsluchania.txt | join -1 3 -2 2 -t ',' - utwor.txt -o 2.3 | sort -t ',' -S 16G --parallel=6 | uniq -c | sort -S 16G --parallel=6 -nr | head -n 1
}

#zle jest :C
function query4() {
    #sort -S 16G --parallel=6 -u -t ',' -nr -k4 odsluchania.txt | join -t ',' -1 4 -2 1 -o 2.3 - data.txt | sort -S 16G --parallel=6 | uniq -c | mawk -F ' ' ' { print $2, $1 } ' | sort

    awk -F '<SEP>' '{ print strftime("%m", $3); }' triplets_sample_20p.txt | sort -S 16G --parallel=6 | uniq -c | awk '{print $2, $1}' | sort
}

function query5() {
    grep -F ',Queen,' utwor.txt | cut -d ',' -f2 > queen_songs_id
    grep -Ff queen_songs_id odsluchania.txt | cut -d ',' -f3 | sort | uniq -c | sort -nr | head -n 3 | tr -s ' ' | cut -d ' ' -f3 > top3_queen_songs
    grep -Ff top3_queen_songs odsluchania.txt | cut -d ',' -f2,3 | uniq | cut -d ',' -f1 | uniq -c | tr -s ' ' ',' | mawk -F ',' '$2 >= 3 {print $3} ' | sort | head

    rm -f top3_queen_songs queen_songs_id
}

function query1() {
    cut -d ',' -f3 odsluchania.txt | sort -S 16G --parallel=6 | uniq -c | sort -S 16G --parallel=6 -nr | head -n 10 | tr -s ' ' ',' | cut -d ',' -f2,3,4 > top10_songs_nr
    cut -d ',' -f2 top10_songs_nr > top10_songs
    grep -Ff top10_songs utwor.txt > top10_songs_plus_utwor
    sort -t ',' -k2 top10_songs_plus_utwor > top10_songs_plus_utwor_sorted
    sort -t ',' -k2 top10_songs_nr > top10_songs_nr_sorted
    join -t ',' top10_songs_plus_utwor_sorted top10_songs_nr_sorted -1 2 -2 2 > top10
    mawk -F ',' '{ print $NF, $0 }' top10 | sort -nr -k1 | sed 's/^[0-9][0-9]* //' > top10_sorted
    cut -d ',' -f4,5 top10_sorted | tr ',' ' '

    rm -f top10*
}

function run_queries() {
    START=$(date +%s.%N)

    for i in $(seq 1 5); do
        printf "starting with query%s...\n" "$i"
        $(printf "query%s" "$i")
        printf "starting with query%s... done\n\n" "$i"
    done 

    END=$(date +%s.%N)
    echo -n "query1 time elapsed: "
    echo "$END - $START" | bc
}

if [ ! -f ./odsluchania.txt ] || [ ! -f ./data.txt ] || [ ! -f ./utwor.txt ]; then
    echo "db files doesnt exist..."
    create
else
    echo "db files exist... proceeding with queries"
fi


START=$(date +%s.%N)

run_queries

END=$(date +%s.%N)
echo -n "query1 time elapsed: "
echo "$END - $START" | bc