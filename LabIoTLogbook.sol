// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LabIoTLogbook {
    struct Peminjaman {
        string namaAlat;
        string namaPeminjam;
        uint256 waktuPinjam;
        uint256 waktuKembali;
        bool statusKembali;
        bool dibatalkan;
        address walletPeminjam;
    }

    Peminjaman[] private logbook;

    event AlatDipinjam(uint256 id, string namaAlat, address peminjam);
    event AlatDikembalikan(uint256 id);
    event PeminjamanDibatalkan(uint256 id);

    function pinjamAlat(string calldata _namaAlat, string calldata _namaPeminjam) external {
        logbook.push(Peminjaman({
            namaAlat: _namaAlat,
            namaPeminjam: _namaPeminjam,
            waktuPinjam: block.timestamp,
            waktuKembali: 0,
            statusKembali: false,
            dibatalkan: false,
            walletPeminjam: msg.sender
        }));
        emit AlatDipinjam(logbook.length - 1, _namaAlat, msg.sender);
    }

    function kembalikanAlat(uint256 id) external {
        require(id < logbook.length, "Data peminjaman tidak ada");
        require(logbook[id].walletPeminjam == msg.sender, "Bukan peminjam alat ini");
        require(!logbook[id].statusKembali, "Alat sudah dikembalikan");
        require(!logbook[id].dibatalkan, "Peminjaman ini sudah dibatalkan");

        logbook[id].statusKembali = true;
        logbook[id].waktuKembali = block.timestamp;
        emit AlatDikembalikan(id);
    }

    // --- FITUR TAMBAHAN BONUS: Membatalkan peminjaman oleh pembuatnya ---
    function batalkanPeminjaman(uint256 id) external {
        require(id < logbook.length, "Data peminjaman tidak ada");
        require(logbook[id].walletPeminjam == msg.sender, "Bukan peminjam alat ini");
        require(!logbook[id].statusKembali, "Alat sudah dikembalikan, tidak bisa dibatalkan");
        require(!logbook[id].dibatalkan, "Sudah dibatalkan sebelumnya");

        logbook[id].dibatalkan = true;
        emit PeminjamanDibatalkan(id);
    }

    function jumlahLog() external view returns (uint256) {
        return logbook.length;
    }

    function ambilLog(uint256 id) external view returns (string memory, string memory, uint256, uint256, bool, bool, address) {
        Peminjaman memory p = logbook[id];
        return (p.namaAlat, p.namaPeminjam, p.waktuPinjam, p.waktuKembali, p.statusKembali, p.dibatalkan, p.walletPeminjam);
    }
}