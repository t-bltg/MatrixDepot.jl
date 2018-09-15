mdinfo()
groups = ["symmetric", "inverse", "illcond", "posdef", "eigen","sparse", "random", "regprob", "all"]

for group in groups 
    mdlist(Symbol(group))
end

@test_throws DataError matrixdepot("something")

n = rand(1:55)
name = list(builtin(n))
mdinfo(name)

nlist = list(builtin([1, 3]) | builtin(4:20))
m = length(list("**"))
@test isempty(mdinfo(builtin(m+1)))

@addgroup newlist = list(builtin(3:6) | builtin(20))

MatrixDepot.init()

println(mdlist(:newlist))

@rmgroup newlist

# testing the new API
#
# it is assumed that all matrices generated during "test/dowlnload.jl"
# and the ibuiltin- and user-defined "randsym" but no others are available
#

@testset "list" begin

REM = length(list("*/*"))
@test REM in [2757, 2833]   # depends on whether ufl or tamu url has been used
@test length(list(:builtin)) == 59
@test length(list(:user)) in [0, 1]

@test list("") == []
@test list("HB/1138_bus") == ["HB/1138_bus"]
@test list(uf(1)) == ["HB/1138_bus"]
@test list(mm(1)) == ["Harwell-Boeing/psadmit/1138_bus"]
@test sort(list(uf(1:3000))) == list("*/*")
@test sort(list(mm(1:3000))) == list("*/*/*")
@test list(builtin(:)) == list(isbuiltin)
@test list(user(:)) == list(isuser)
@test list("*") == list(islocal)
@test length(list("HB/*")) == 292
@test list("HB**") == list("HB/**")
@test_throws ArgumentError  listdir("*/*")
@test listdir("Harwell-Boeing//") == ["Harwell-Boeing/*/* - (292)"]
@test list("*/hamm/*") == ["misc/hamm/add20", "misc/hamm/add32", "misc/hamm/memplus"]
@test list("*/hamm/*a*3?") == ["misc/hamm/add32"]
@test list("*/hamm/*a*3[123]") == ["misc/hamm/add32"]
@test list("*/hamm/*a*3[123]?") == []
@test length(list("*/*/*")) == 498

@test listdir("*//*/*") == ["Harwell-Boeing/*/* - (292)", "NEP/*/* - (73)",
                           "SPARSKIT/*/* - (107)", "misc/*/* - (26)"]
@test listdir("//*") == ["/* - ($(length(list(:local))))"]
@test listdir("//*/*") == ["/*/* - ($REM)"]
@test listdir("//*/*/*") == ["/*/*/* - (498)"]
@test listdir("HB/") == ["HB/* - (292)"]
@test length(list("Harwell-Boeing/*/*")) == 292
@test list(r".*ng/ma.*") == ["Harwell-Boeing/manteuffel/man_5976"]
@test list(tamu(2001:2002)) == ["JGD_Groebner/c8_mat11_I", "JGD_Groebner/f855_mat9"]
@test length(list(tamu(2757:3000))) == REM - 2756
@test_throws ArgumentError list(:xxx)
@test length(list(isremote)) == REM + 498
@test length(list(isloaded)) + length(list(isunloaded)) == length(list(isremote))
@test length(list(isbuiltin)) + length(list(isuser)) == length(list(islocal))
@test length(list(islocal)) + length(list(isremote)) == length(list(:all))
@test length(list("**")) == length(list("*")) + length(list("*/*")) + length(list("*/*/*"))
@test list(:all) == list("**")
@test length(list(:symmetric)) == 22
@test length(list(:illcond)) == 20

# intersections and unions
@test list((:posdef, :sparse)) == ["poisson", "wathen"]
@test length(list([:posdef,:sparse])) + length(list((:posdef,:sparse))) == length(list(:posdef)) + length(list(:sparse))


# predicates of remote and local matrices
@test length(list(issymmetric)) == 30

@test length(list(predm(n -> n < 10000))) == 1671   # items with m < *
@test length(list(predm(n -> n < 10000) & isloaded)) == 10   # items with m < *
@test length(list(predn(n -> n < 10000))) == 1611   # items with n < *
@test length(list(predn(n -> n < 10000) &  isloaded)) == 9    # items with n < *
@test length(list(prednz(n -> n < 5000))) == 600    # items with nnz < *
@test length(list(prednz(n -> n < 5000) & isloaded)) == 2    # items with nnz < *
@test length(list(predmn((m,n) -> m > n))) == 178   # items with m > n
@test length(list(predmn((m,n) -> m > n) & isloaded)) == 0   # items with m > n
@test length(list(kindhas("Power"))) == 70
@test length(list(datebefore(1971))) == 5
@test length(list(dateafter(2016) & datebefore(2016))) == 2
@test length(list(nodate & uf(:))) == 42
@test list(prednzdev(0.001)) == ["DRIVCAV/cavity14"] 

@test list(:local) == list(islocal)
@test list(:builtin) == list(isbuiltin)
@test list(:user) == list(isuser)

@test list(:symmetric) == list(issymmetric & islocal)
end

@testset "logical" begin
# for the boolean syntax
@test list(¬islocal) == list(isremote)
@test length(list(isloaded & issymmetric)) == 7
@test length(list(isloaded & ¬issymmetric)) == 4
@test length(list(isloaded & ¬issymmetric | isuser & issymmetric)) == 5
@test length(list(!islocal & issymmetric | isuser & issymmetric)) == 9
@test list(islocal & ¬isbuiltin) == list(isuser)
@test list(islocal & ¬isbuiltin) == list(isuser)
@test "a" & "b" === ("a", "b")
@test ¬"a" & "b" === (¬"a", "b")
@test ¬"a" * "b" === ¬"ab"
@test ¬"ab" === ¬'a' * 'b'
@test ¬¬islocal === islocal
@test list(¬"*a*" & ¬ "*e*") == list(¬["*a*", "*e*"])
@test list(()) == list(:all)
@test "a" & r"b" == ("a", r"b")
@test "a" & r"b" & "c" == ("a", r"b", "c")
@test "a" | r"b" == ["a", r"b"]
@test "a" | r"b" | "c" == ["a", r"b", "c"]
@test list(islocal & ¬("*a*" | "*e*")) == list(:local & ¬"*a*" & ¬ "*e*")
@test "a" & ( "b" & "c" ) == ("a", "b", "c")
@test "a" | ( "b" | "c" ) == ["a", "b", "c"]
@test_throws ArgumentError list([] & :invalid_group_name)

@test MatrixDepot.list(builtin(10, 1:7, 3)) == ["baart", "binomial", "blur", "cauchy",
                                                "chebspec", "chow", "circul", "deriv2"] 

@test MatrixDepot.fname(sin) == "unknown-function"
@test_throws MethodError mdopen("baart", 10, 11)
end

