# Shokunin Memory Benchmark

Measures recall accuracy of Shokunin's memory retrieval system.

## Methodology

1. Seed ChromaDB with 5 known entries containing specific keywords
2. Run 5 queries against both `search` (vector-only) and `recall` (multi-strategy: BM25 + vector + RRF)
3. Check if the correct entry appears in the top 5 results
4. Report recall@5 accuracy for each method

## Results (latest)

| Method | Found | Accuracy |
|--------|-------|----------|
| Vector-only (search) | 5/5 | 100% |
| Multi-strategy (recall) | 5/5 | 100% |

## Run

```bash
python benchmarks/benchmark_memory.py
```

## Limitations

This benchmark measures recall accuracy on a clean dataset. It does not measure:
- End-user productivity improvement
- Task completion time
- Accuracy on noisy/accumulated data from weeks of usage

The real advantage of multi-strategy retrieval appears in real-world scenarios where accumulated noise dilutes vector similarity and BM25 catches exact keywords that embedding models miss.

## Data

- Dataset: 5 seeded entries in ChromaDB (plus existing ~120 production entries)
- Embedding model: all-MiniLM-L6-v2
- BM25: in-memory Python TF-IDF
- RRF: k=60 reciprocal rank fusion
