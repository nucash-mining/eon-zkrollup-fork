package rollup

import (
    "github.com/ethereum/go-ethereum/common"
)

// Node for dual-sync: ACC mainnet + L2 zkRollup
type Node struct {
    accRPC string  // "http://localhost:8545"
    l2RPC  string  // "http://localhost:8546"
}

func (n *Node) SyncDual() error {
    // Query ACC staking contract for online status
    // Sync L2 batches to zhash Cysic proofs
    return nil
}

func NewNode(accRPC, l2RPC string) *Node {
    return &Node{accRPC: accRPC, l2RPC: l2RPC}
}
