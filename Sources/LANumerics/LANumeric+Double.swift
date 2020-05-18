import Accelerate

extension Double : LANumeric {
        
    public static func manhattanNorm(_ vector : Vector<Double>) -> Double {
        return cblas_dasum(Int32(vector.count), vector, 1)
    }
    
    public static func euclideanNorm(_ vector : Vector<Double>) -> Double {
        return cblas_dnrm2(Int32(vector.count), vector, 1)
    }

    public static func scaleVector(_ alpha : Self, _ A : inout Vector<Self>) {
        let C = Int32(A.count)
        asMutablePointer(&A) { A in
            cblas_dscal(C, alpha, A, 1)
        }
    }
    
    public static func scaleAndAddVectors(_ alpha : Double, _ A : Vector<Double>, _ beta : Double, _ B : inout Vector<Double>) {
        precondition(A.count == B.count)
        asMutablePointer(&B) { B in
            catlas_daxpby(Int32(A.count), alpha, A, 1, beta, B, 1)
        }
    }
    
    public static func indexOfLargestElem(_ vector: Vector<Double>) -> Int {
        guard !vector.isEmpty else { return -1 }
        return Int(cblas_idamax(Int32(vector.count), vector, 1))
    }

    public static func dotProduct(_ A: Vector<Double>, _ B: Vector<Double>) -> Double {
        precondition(A.count == B.count)
        return cblas_ddot(Int32(A.count), A, 1, B, 1)
    }

    public static func matrixProduct(_ alpha : Self, _ transposeA : Bool, _ A : Matrix<Self>, _ transposeB : Bool, _ B : Matrix<Self>, _ beta : Self, _ C : inout Matrix<Self>) {
        let M = Int32(transposeA ? A.columns : A.rows)
        let N = Int32(transposeB ? B.rows : B.columns)
        let KA = Int32(transposeA ? A.rows : A.columns)
        let KB = Int32(transposeB ? B.columns : B.rows)
        precondition(KA == KB)
        precondition(M == C.rows)
        precondition(N == C.columns)
        asMutablePointer(&C.elements) { C in
            let ta = transposeA ? CblasTrans : CblasNoTrans
            let tb = transposeB ? CblasTrans : CblasNoTrans
            cblas_dgemm(CblasColMajor, ta, tb, M, N, KA, alpha, A.elements, Int32(A.rows), B.elements, Int32(B.rows), beta, C, M)
        }
    }
    
    public static func matrixVectorProduct(_ alpha : Self, _ transposeA : Bool, _ A : Matrix<Self>, _ X : Vector<Self>, _ beta : Self, _ Y : inout Vector<Self>) {
        let M = Int32(A.rows)
        let N = Int32(A.columns)
        precondition(transposeA ? (N == Y.count) : (N == X.count))
        precondition(transposeA ? (M == X.count) : (M == Y.count))
        asMutablePointer(&Y) { Y in
            let ta = transposeA ? CblasTrans : CblasNoTrans
            cblas_dgemv(CblasColMajor, ta, M, N, alpha, A.elements, M, X, 1, beta, Y, 1)
        }
    }

    public static func vectorVectorProduct(_ alpha : Self, _ X : Vector<Self>, _ Y : Vector<Self>, _ A : inout Matrix<Self>) {
        let M = Int32(A.rows)
        let N = Int32(A.columns)
        precondition(M == X.count)
        precondition(N == Y.count)
        asMutablePointer(&A.elements) { A in
            cblas_dger(CblasColMajor, M, N, alpha, X, 1, Y, 1, A, M)
        }
    }
    
    public static func solveLinearEquations(_ A : Matrix<Self>, _ B : inout Matrix<Self>) -> Bool {
        var n = Int32(A.rows)
        precondition(A.columns == n && B.rows == n)
        var lda = n
        var ldb = n
        var info : Int32 = 0
        var nrhs = Int32(B.columns)
        var ipiv = [Int32](repeating: 0, count: Int(n))
        var A = A.elements
        asMutablePointer(&A) { A in
            asMutablePointer(&B.elements) { B in
                asMutablePointer(&ipiv) { ipiv in
                    let _ = dgesv_(&n, &nrhs, A, &lda, ipiv, B, &ldb, &info)
                }
            }
        }
        return info == 0
    }
    
    public static func solveLinearLeastSquares(_ A : Matrix<Self>, _ transposeA : Bool, _ B : Matrix<Self>) -> Matrix<Self>? {
        fatalError()
    }

}


