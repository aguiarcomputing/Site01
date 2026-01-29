<?php
// salvar-cadastro.php - Versão FINAL 100% funcional
header('Content-Type: text/html; charset=utf-8');

// ========================================
// 1. CAMINHO DO BANCO ACCESS
// ========================================
$dbPath = "D:\\Site01\\Site01\\Databasesite1.accdb";

if (!file_exists($dbPath)) {
    die("<h3 style='color:red; text-align:center; margin-top:100px;'>ERRO: Banco de dados não encontrado!<br>$dbPath</h3>");
}

// ========================================
// 2. CONEXÃO COM ACCESS (PDO + ODBC)
// ========================================
try {
    $conn = new PDO("odbc:Driver={Microsoft Access Driver (*.mdb, *.accdb)};Dbq=$dbPath;Uid=;Pwd=;");
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (Exception $e) {
    die("<h3 style='color:red; text-align:center; margin-top:100px;'>Erro de conexão com o banco:<br>" . htmlspecialchars($e->getMessage()) . "</h3>");
}

// ========================================
// 3. RECEBE E LIMPA OS DADOS
// ========================================
$nome_cliente = trim($_POST['nome_cliente'] ?? '');
$whatsapp     = preg_replace('/\D/', '', $_POST['whatsapp'] ?? ''); // só números
$tipo         = $_POST['tipo'] ?? '';
$marca        = trim($_POST['marca'] ?? '');
$modelo       = trim($_POST['modelo'] ?? '');
$serial       = trim($_POST['serial'] ?? '');
$problema     = trim($_POST['problema'] ?? '');
$acessorios   = trim($_POST['acessorios'] ?? '');
$observacoes  = trim($_POST['observacoes'] ?? '');

// Validação obrigatória
if (empty($nome_cliente) || empty($whatsapp) || empty($tipo) || empty($marca) || empty($problema)) {
    die("<h3 style='color:red; text-align:center; margin-top:100px;'>Erro: Todos os campos obrigatórios devem ser preenchidos!</h3>");
}

// ========================================
// 4. INSERE NO BANCO
// ========================================
$sql = "INSERT INTO cadastros_equipamentos 
        (data_cadastro, nome_cliente, whatsapp, tipo, marca, modelo, serial, problema, acessorios, observacoes, status) 
        VALUES 
        (Now(), ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Recebido')";

$stmt = $conn->prepare($sql);
$stmt->execute([
    $nome_cliente,
    $whatsapp,
    $tipo,
    $marca,
    $modelo,
    $serial,
    $problema,
    $acessorios,
    $observacoes
]);

// Pega o ID gerado (AutoNumeração)
$id = $conn->lastInsertId();
$protocolo = str_pad($id, 5, '0', STR_PAD_LEFT); // Ex: 00001, 00123

// ========================================
// 5. TELA DE SUCESSO BONITA (com seu estilo original)
// ========================================
?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <title>Cadastro Salvo com Sucesso - Aguiar Informática</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link href="css/bootstrap.min.css" rel="stylesheet">
    <link href="css/style.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.10.0/css/all.min.css" rel="stylesheet">
    <style>
        .success-box { margin-top: 100px; padding: 50px; background: #fff; border-radius: 15px; box-shadow: 0 10px 30px rgba(0,0,0,0.1); }
        .protocolo { font-size: 3rem; font-weight: bold; color: #27ae60; }
    </style>
</head>
<body class="bg-light">

    <!-- Navbar (mesmo do seu site) -->
    <?php include('navbar.php'); ?> <!-- opcional: crie um navbar.php se quiser -->

    <div class="container">
        <div class="row justify-content-center">
            <div class="col-lg-8">
                <div class="success-box text-center wow fadeInUp" data-wow-delay="0.3s">
                    <h1 class="text-success display-3 mb-4">
                        <i class="fas fa-check-circle"></i> Cadastro salvo com sucesso!
                    </h1>
                    <p class="lead">Seu equipamento foi registrado no sistema.</p>
                    
                    <div class="protocolo mb-4">#<?php echo $protocolo; ?></div>
                    
                    <hr class="my-5">

                    <p class="fs-4">Olá <strong><?php echo htmlspecialchars($nome_cliente); ?></strong>,</p>
                    <p>Obrigado por confiar na <strong>Aguiar Informática</strong>!<br>
                    Em breve entraremos em contato pelo WhatsApp <strong>(<?php echo substr($whatsapp,0,2); ?> <?php echo substr($whatsapp,2,5); ?>-<?php echo substr($whatsapp,7); ?>)</strong></p>

                    <div class="mt-5">
                        <a href="https://wa.me/55<?php echo $whatsapp; ?>?text=<?php 
                            echo urlencode("Olá $nome_cliente! Seu equipamento foi cadastrado com sucesso!\n\nProtocolo: #$protocolo\nTipo: $tipo $marca $modelo\nProblema: $problema\n\nEm breve entraremos em contato.\n\nAtt,\nAguiar Informática ✨");
                        ?>" target="_blank" class="btn btn-success btn-lg rounded-pill px-5 py-3 me-3">
                            <i class="fab fa-whatsapp fa-2x align-middle"></i> Abrir WhatsApp do Cliente
                        </a>
                        
                        <a href="cadastro-equipamento.html" class="btn btn-primary btn-lg rounded-pill px-5 py-3">
                            <i class="fa fa-plus"></i> Novo Cadastro
                        </a>
                    </div>

                    <div class="mt-5 text-muted">
                        <small>Aguiar Informática • São José/SC • (48) 99189-0567</small>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Scripts do seu template -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.6.4/jquery.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0/dist/js/bootstrap.bundle.min.js"></script>
    <script src="lib/wow/wow.min.js"></script>
    <script src="js/main.js"></script>
    <script>new WOW().init();</script>
</body>
</html>
<?php
// Fim do script
?>