% =========================================================================
% DESCRIPCIÓN: Simulador interactivo del campo eléctrico generado por dos
%              líneas de carga (una positiva y una negativa) ubicadas en
%              posiciones simétricas respecto al origen.
%
% La aplicación permite al usuario modificar interactivamente:
%   - La distancia entre las líneas de carga
%   - La magnitud de las cargas positivas y negativas
%   - La cantidad de cargas puntuales en cada línea
%   - La longitud de cada línea de carga
%   - El número de puntos de la malla donde se evalúa el campo
%   - Un punto específico (x, y) donde se calcula la magnitud del campo
%
% La visualización muestra el campo eléctrico mediante vectores normalizados
% (quiver) y representa gráficamente las cargas como círculos de colores.
% =========================================================================
classdef otrabes < matlab.apps.AppBase

    % =====================================================================
    % PROPIEDADES PÚBLICAS - Componentes de la interfaz gráfica
    % =====================================================================
    % Cada propiedad corresponde a un componente visual de la aplicación
    % (etiquetas, sliders, campos de edición, ejes, botones, etc.)
    properties (Access = public)
        UIFigure                  matlab.ui.Figure              % Ventana principal de la app
        MagnituddelcampoenLabel   matlab.ui.control.Label       % Etiqueta "Magnitud del campo en:"
        yEditField                matlab.ui.control.EditField   % Campo de texto para coordenada Y del punto de evaluación
        yEditFieldLabel           matlab.ui.control.Label       % Etiqueta "y:"
        DistanciaSlider           matlab.ui.control.Slider      % Slider para la distancia entre líneas de carga
        DistanciaSliderLabel      matlab.ui.control.Label       % Etiqueta "Distancia"
        NumPuntosEditField        matlab.ui.control.NumericEditField % Campo numérico: tamaño de la malla NxN
        NumdepuntosLabel          matlab.ui.control.Label       % Etiqueta "Num de puntos:"
        xEditField                matlab.ui.control.EditField   % Campo de texto para coordenada X del punto de evaluación
        xEditFieldLabel           matlab.ui.control.Label       % Etiqueta "x:"
        LongQnSlider              matlab.ui.control.Slider      % Slider para la longitud de la línea de cargas negativas
        LongdelineaSlider_2Label  matlab.ui.control.Label       % Etiqueta "Long de linea" (negativas)
        CantQnSlider              matlab.ui.control.Slider      % Slider para la cantidad de cargas negativas
        CantcargasLabel_2         matlab.ui.control.Label       % Etiqueta "Cant cargas (-)"
        CantQpSlider              matlab.ui.control.Slider      % Slider para la cantidad de cargas positivas
        CantcargasLabel           matlab.ui.control.Label       % Etiqueta "Cant cargas (+)"
        LongQpSlider              matlab.ui.control.Slider      % Slider para la longitud de la línea de cargas positivas
        LongdelineaSliderLabel    matlab.ui.control.Label       % Etiqueta "Long de linea" (positivas)
        MagnitudQnEditField       matlab.ui.control.NumericEditField % Magnitud (valor absoluto) de las cargas negativas
        MagnituddecargasLabel_3   matlab.ui.control.Label       % Etiqueta "Magnitud de cargas (-)"
        MagnitudQpEditField       matlab.ui.control.NumericEditField % Magnitud de las cargas positivas
        MagnituddecargasLabel_4   matlab.ui.control.Label       % Etiqueta "Magnitud de cargas (+)"
        simularButton             matlab.ui.control.Button      % Botón para ejecutar la simulación
        UIAxes                    matlab.ui.control.UIAxes      % Ejes donde se grafica el campo eléctrico
    end

    
    % =====================================================================
    % MÉTODOS PRIVADOS - Lógica interna de la aplicación
    % =====================================================================
    methods (Access = private)
        
        % -----------------------------------------------------------------
        % FUNCIÓN: graficarLineas
        % -----------------------------------------------------------------
        % Calcula y grafica el campo eléctrico producido por dos líneas de
        % cargas puntuales (una positiva y una negativa) y dibuja el vector
        % de campo en cada punto de una malla NxN.
        %
        % PARÁMETROS DE ENTRADA:
        %   d           - Distancia entre las dos líneas de carga
        %   Qp          - Magnitud de cada carga positiva (signo +)
        %   Qn          - Magnitud de cada carga negativa (signo -)
        %   N           - Número de puntos por lado de la malla (NxN)
        %   ncargas_p   - Cantidad de cargas puntuales en la línea positiva
        %   ncargas_n   - Cantidad de cargas puntuales en la línea negativa
        %   linea_lon_p - Longitud de la línea de cargas positivas
        %   linea_lon_n - Longitud de la línea de cargas negativas
        %   app         - Referencia a la app (para acceder a los UIAxes)
        %   x0, y0      - Coordenadas del punto donde se evalúa la magnitud
        % -----------------------------------------------------------------
        function results = graficarLineas(d, Qp, Qn, N, ncargas_p, ncargas_n, linea_lon_p, linea_lon_n, app,x0,y0)
            
            % --- Definición de los límites del área de graficación --------
            % Se establece una región cuadrada centrada en el origen
            lsx = 5; lix = -5;   % Límite superior e inferior en X
            lsy = 5; liy = -5;   % Límite superior e inferior en Y
            
            % --- Construcción de la malla (meshgrid) ----------------------
            % Se generan N puntos equiespaciados en X y en Y, formando una
            % matriz NxN de coordenadas donde se evaluará el campo eléctrico
            x = linspace(lix, lsx, N);  % Vector de coordenadas X
            y = linspace(liy, lsy, N);  % Vector de coordenadas Y
            [xG, yG] = meshgrid(x, y);  % Matrices NxN de coordenadas (x,y)
            
            
            % --- Posicionamiento de las cargas ----------------------------
            % Las líneas de carga se ubican simétricamente respecto al eje Y:
            %   - Cargas positivas: en x = -d/2, distribuidas verticalmente
            %   - Cargas negativas: en x = +d/2, distribuidas verticalmente
            % linspace genera ncargas puntos uniformemente distribuidos en
            % el rango [-linea_lon/2, +linea_lon/2]
            xCp = -d/2; yCp = linspace(-(linea_lon_p/2), linea_lon_p/2, ncargas_p);    % Posiciones de cargas positivas
            xCn =  d/2; yCn = linspace(-(linea_lon_n/2), linea_lon_n/2, ncargas_n);    % Posiciones de cargas negativas
            
            % --- Inicialización de las componentes del campo --------------
            % Se inicializan en cero las matrices que acumularán el campo
            % eléctrico total por superposición de cada carga
            Ex = zeros(N); Ey = zeros(N);
            
            % --- Constantes físicas ---------------------------------------
            epsO = 8.854e-12;            % Permitividad del vacío (F/m)
            kC = 1 / (4 * pi * epsO);    % Constante de Coulomb (≈ 8.99e9 N·m²/C²)
            
            % =============================================================
            % CÁLCULO DEL CAMPO ELÉCTRICO DE LAS CARGAS POSITIVAS
            % =============================================================
            % Variables auxiliares para el campo en el punto específico (x0, y0)
            Ex0 = 0;
            Ey0 = 0;
            
            % Iteramos sobre cada carga positiva y aplicamos superposición
            for i = 1:ncargas_p
                
                % --- Vector posición desde la carga hacia cada punto ------
                % Componentes del vector r = punto - carga
                Rx = xG - xCp;       % Componente X del vector posición
                Ry = yG - yCp(i);    % Componente Y del vector posición
                r = sqrt(Rx.^2 + Ry.^2);  % Magnitud (distancia escalar)
                r(r == 0) = 1e-12;   % Se evita división por cero asignando un valor mínimo
                
                % --- Cálculo del campo eléctrico ------------------------
                % Fórmula vectorial: E = k * q / r² * r̂
                % Donde r̂ = (Rx, Ry) / r, por lo que:
                %       E = k * q * (Rx, Ry) / r³
                Ex = Ex + kC .* Qp .* Rx ./ (r.^3);  % Acumular componente X
                Ey = Ey + kC .* Qp .* Ry ./ (r.^3);  % Acumular componente Y
                
                % --- Cálculo del campo en el punto (x0, y0) ---------------
                % Se realiza el mismo cálculo de manera escalar para el
                % punto específico que el usuario quiere evaluar
                Rx0 = x0 - xCp;
                Ry0 = y0 - yCp(i);
                r0 = sqrt(Rx0^2 + Ry0^2);
                if r0 == 0
                    r0 = 1e-12;  % Evitar singularidad
                end
                
                Ex0 = Ex0 + kC * Qp * Rx0 / (r0^3);
                Ey0 = Ey0 + kC * Qp * Ry0 / (r0^3);
                
            end
            
            % =============================================================
            % CÁLCULO DEL CAMPO ELÉCTRICO DE LAS CARGAS NEGATIVAS
            % =============================================================
            % NOTA: Aquí no se acumula el campo en (x0, y0); solo se
            % considera la contribución de las cargas positivas para Ex0/Ey0.
            for i = 1:ncargas_n
                
                % --- Vector posición desde la carga negativa --------------
                Rx = xG - xCn;
                Ry = yG - yCn(i);
                r = sqrt(Rx.^2 + Ry.^2);
                r(r == 0) = 1e-12;
                
                % --- Superposición del campo eléctrico --------------------
                % Como Qn ya viene con signo negativo desde init(), 
                % esto naturalmente resta el campo correspondiente
                Ex = Ex + kC .* (Qn) .* Rx ./ (r.^3);
                Ey = Ey + kC .* (Qn) .* Ry ./ (r.^3);
                
            end

            % --- Magnitud del campo en el punto evaluado (x0, y0) ---------
            E0 = sqrt(Ex0^2 + Ey0^2);
            
            % =============================================================
            % NORMALIZACIÓN DE LOS VECTORES DEL CAMPO
            % =============================================================
            % Como las magnitudes del campo varían enormemente (muy fuerte
            % cerca de las cargas, muy débil lejos), se normalizan los
            % vectores para mostrar únicamente la DIRECCIÓN del campo en
            % cada punto. Así la visualización con quiver es más legible.
            E = sqrt(Ex.^2 + Ey.^2);   % Magnitud del campo en cada punto
            E(E == 0) = 1e-12;          % Evitar división por cero
            u = Ex ./ E;                % Componente X normalizada (vector unitario)
            v = Ey ./ E;                % Componente Y normalizada
            
            % --- Graficar el campo vectorial ------------------------------
            % quiver dibuja una flecha en cada punto (xG, yG) con dirección (u, v)
            quiver(app.UIAxes,xG, yG, u, v, 'autoscalefactor', 0.5);

            % --- Configuración de los ejes --------------------------------
            axis(app.UIAxes, "equal");                 % Misma escala en X y Y
            axis(app.UIAxes, [lix lsx liy lsy] )       % Límites fijos del gráfico
            hold(app.UIAxes,"on");                     % Mantener el gráfico para superponer

            % --- Dibujar el punto de evaluación (x0, y0) ------------------
            plot(app.UIAxes,x0, y0, 'ko', 'MarkerFaceColor', 'y', 'MarkerSize', 8);
            
            % --- Mostrar el valor de la magnitud del campo en (x0, y0) ----
            % Se muestra el resultado en notación científica al lado del punto
            texto = sprintf('E = %.2e N/C', E0);
            text(app.UIAxes,x0 + 0.2, y0, texto, 'FontSize', 10, 'Color', 'k', 'BackgroundColor','w');
            
            % =============================================================
            % REPRESENTACIÓN GRÁFICA DE LAS CARGAS
            % =============================================================
            % Las cargas se dibujan como círculos (rectángulos con curvatura
            % completa = [1 1]) con color y símbolo según el signo:
            %   - Carga positiva: rojo con '+'
            %   - Carga negativa: azul con '-'
            
            % --- Determinar color y símbolo de cargas positivas -----------
            if (Qp > 0)
               cQp = 'r'; tQp = '+';   % Rojo y signo +
            else
               cQp = 'b'; tQp = '-';   % Azul y signo -
            end
            
            % --- Determinar color y símbolo de cargas negativas -----------
            if (Qn > 0)
               cQn = 'r'; tQn = '+';
            else
               cQn = 'b'; tQn = '-';
            end
            
            % --- Cálculo del tamaño visual de las cargas ------------------
            % El tamaño de cada círculo se basa en la separación entre cargas
            % consecutivas para que no se solapen. Se toma el menor de ambos
            % tamaños para mantener consistencia visual entre líneas.
            dy_p = abs(yCp(2) - yCp(1));   % Distancia entre cargas positivas
            dy_n = abs(yCn(2) - yCn(1));   % Distancia entre cargas negativas
            a_p = 0.7 * dy_p;              % Tamaño base (positivas)
            a_n = 0.7 * dy_n;              % Tamaño base (negativas)
            a_p = min(a_n, a_p);           % Tomamos el menor para uniformidad
            
            % --- Dibujar todas las cargas positivas -----------------------
            for index = 1:ncargas_p
                % rectangle con Curvature = [1 1] dibuja una elipse/círculo
                rectangle(app.UIAxes,'Position', [xCp - a_p/2, yCp(index) - a_p/2, a_p, a_p], 'Curvature', [1 1], 'FaceColor', cQp);
                % Texto del símbolo (+ o -) centrado en la carga
                text(app.UIAxes,xCp-0.05, yCp(index), tQp, 'Color', 'white', 'FontSize', 10);
            end
            
            % --- Dibujar todas las cargas negativas -----------------------
            for index = 1:ncargas_n
              rectangle(app.UIAxes,'Position', [xCn - a_p/2, yCn(index) - a_p/2, a_p, a_p], 'Curvature', [1 1], 'FaceColor', cQn);
              text(app.UIAxes,xCn-0.05, yCn(index), tQn, 'Color', 'white', 'FontSize', 10);
            end
        end
       
        
        % -----------------------------------------------------------------
        % FUNCIÓN: init
        % -----------------------------------------------------------------
        % Función principal que se llama cada vez que el usuario modifica
        % algún parámetro o presiona el botón SIMULAR. Lee los valores
        % actuales de todos los controles de la interfaz, limpia los ejes
        % y vuelve a graficar el campo con los nuevos parámetros.
        % -----------------------------------------------------------------
        function results = init(app)
            cla(app.UIAxes);  % Limpia los ejes antes de redibujar
            
            % --- Lectura de valores desde la interfaz gráfica -------------
            d = app.DistanciaSlider.Value;                  % Distancia entre líneas
            Qp = app.MagnitudQpEditField.Value;             % Magnitud cargas positivas
            Qn = -(app.MagnitudQnEditField.Value);          % Magnitud cargas negativas (se invierte el signo)
            N = app.NumPuntosEditField.Value;               % Resolución de la malla
            ncargas_p = app.CantQpSlider.Value;             % Cantidad de cargas positivas
            ncargas_n = app.CantQnSlider.Value;             % Cantidad de cargas negativas
            linea_lon_p = app.LongQpSlider.Value;           % Longitud línea positiva
            linea_lon_n = app.LongQnSlider.Value;           % Longitud línea negativa
            x0 = str2double(app.xEditField.Value);          % Coordenada X del punto de evaluación
            y0 = str2double(app.yEditField.Value);          % Coordenada Y del punto de evaluación
   
            % --- Llamada a la función de graficación ----------------------
            graficarLineas(d,Qp,Qn,N,ncargas_p,ncargas_n, linea_lon_p,linea_lon_n,app,x0,y0);
        end
        
        % -----------------------------------------------------------------
        % FUNCIÓN: func3 (auxiliar - actualmente sin uso desde la UI)
        % -----------------------------------------------------------------
        % Esta función está pensada para calcular la magnitud del campo
        % eléctrico en un conjunto arbitrario de puntos dados como matriz Nx2.
        % 
        % NOTA: Esta función parece estar incompleta o no integrada en la
        %       aplicación: las variables 'puntos', 'd', 'Qp', 'Qn',
        %       'ncargas_p', 'ncargas_n', 'linea_lon_p' y 'linea_lon_n'
        %       no están definidas como parámetros de entrada, por lo que
        %       el código fallaría si se llamara tal cual está.
        %       Considera convertirla a:
        %           function magnitudes = func3(app, puntos, d, Qp, Qn, ...)
        %       o eliminarla si ya no se usa.
        % -----------------------------------------------------------------
        function results = func3(app)
            % Calcula la magnitud del campo eléctrico en puntos específicos
            % puntos: matriz de Nx2 donde cada fila es [x, y]
        
            % --- Constantes físicas ---------------------------------------
            epsO = 8.854e-12;
            kC = 1 / (4 * pi * epsO);
            
            % --- Inicialización de componentes del campo ------------------
            num_puntos = size(puntos, 1);
            Ex_total = zeros(num_puntos, 1);
            Ey_total = zeros(num_puntos, 1);
            
            % --- Posiciones de las cargas ---------------------------------
            xCp = -d/2; 
            yCp = linspace(-(linea_lon_p/2), linea_lon_p/2, ncargas_p);
            xCn =  d/2; 
            yCn = linspace(-(linea_lon_n/2), linea_lon_n/2, ncargas_n);
            
            % --- Aporte de las cargas positivas ---------------------------
            for i = 1:ncargas_p
                Rx = puntos(:,1) - xCp;
                Ry = puntos(:,2) - yCp(i);
                r = sqrt(Rx.^2 + Ry.^2);
                r(r == 0) = 1e-12;  % Evitar división por cero
                
                Ex_total = Ex_total + kC .* Qp .* Rx ./ (r.^3);
                Ey_total = Ey_total + kC .* Qp .* Ry ./ (r.^3);
            end
            
            % --- Aporte de las cargas negativas ---------------------------
            for i = 1:ncargas_n
                Rx = puntos(:,1) - xCn;
                Ry = puntos(:,2) - yCn(i);
                r = sqrt(Rx.^2 + Ry.^2);
                r(r == 0) = 1e-12;
                
                Ex_total = Ex_total + kC .* (Qn) .* Rx ./ (r.^3);
                Ey_total = Ey_total + kC .* (Qn) .* Ry ./ (r.^3);
            end
            
            % --- Magnitud total del campo ---------------------------------
            magnetudes = sqrt(Ex_total.^2 + Ey_total.^2);
        end
    end
    

    % =====================================================================
    % CALLBACKS - Manejadores de eventos de los componentes
    % =====================================================================
    % Cada callback se ejecuta cuando el usuario interactúa con un control.
    % Todos llaman a init(app) para refrescar la simulación con los
    % nuevos valores del usuario.
    methods (Access = private)

        % Callback del botón SIMULAR --------------------------------------
        function simularButtonPushed(app, event)
            init(app)
        end

        % Callback al cambiar la cantidad de cargas positivas -------------
        function CantQpSliderValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la cantidad de cargas negativas -------------
        function CantQnSliderValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la longitud de la línea positiva ------------
        function LongQpSliderValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la longitud de la línea negativa ------------
        function LongQnSliderValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la distancia entre líneas -------------------
        function DistanciaSliderValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la magnitud de las cargas negativas ---------
        function MagnitudQnEditFieldValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la magnitud de las cargas positivas ---------
        function MagnitudQpEditFieldValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar el número de puntos de la malla -------------
        function NumPuntosEditFieldValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la coordenada X del punto evaluado ---------
        function xEditFieldValueChanged(app, event)
            init(app)
        end

        % Callback al cambiar la coordenada Y del punto evaluado ---------
        function yEditFieldValueChanged(app, event)
            init(app)
        end
    end

    % =====================================================================
    % INICIALIZACIÓN DE COMPONENTES - Construcción de la interfaz
    % =====================================================================
    % Aquí se crean y posicionan TODOS los controles visuales de la app.
    % Esta sección es generada/mantenida típicamente por App Designer.
    methods (Access = private)

        % -----------------------------------------------------------------
        % FUNCIÓN: createComponents
        % -----------------------------------------------------------------
        % Crea la ventana principal y todos sus componentes (etiquetas,
        % sliders, campos, botón y ejes), asigna sus propiedades visuales
        % y enlaza los callbacks correspondientes.
        % -----------------------------------------------------------------
        function createComponents(app)

            % --- Creación de la ventana principal -------------------------
            % Se crea oculta (Visible = 'off') y se muestra al final, para
            % evitar que el usuario vea los componentes apareciendo uno a uno.
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [0.9412 0.9412 0.9412];   % Color de fondo (gris claro)
            app.UIFigure.Position = [100 100 932 568];     % [x, y, ancho, alto] de la ventana
            app.UIFigure.Name = 'MATLAB App';

            % --- Crear los ejes para graficar el campo --------------------
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Campo Eléctrico')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.XLim = [-5 5];
            app.UIAxes.YLim = [-5 5];
            app.UIAxes.Position = [189 112 554 393];

            % --- Botón SIMULAR --------------------------------------------
            app.simularButton = uibutton(app.UIFigure, 'push');
            app.simularButton.ButtonPushedFcn = createCallbackFcn(app, @simularButtonPushed, true);
            app.simularButton.Position = [393 30 145 31];
            app.simularButton.Text = 'SIMULAR';

            % --- Etiqueta y campo: Magnitud de cargas (+) -----------------
            app.MagnituddecargasLabel_4 = uilabel(app.UIFigure);
            app.MagnituddecargasLabel_4.Position = [24 112 76 30];
            app.MagnituddecargasLabel_4.Text = {'Magnitud'; 'de cargas (+)'};

            app.MagnitudQpEditField = uieditfield(app.UIFigure, 'numeric');
            app.MagnitudQpEditField.ValueChangedFcn = createCallbackFcn(app, @MagnitudQpEditFieldValueChanged, true);
            app.MagnitudQpEditField.HorizontalAlignment = 'center';
            app.MagnitudQpEditField.Position = [115 120 53 22];
            app.MagnitudQpEditField.Value = 2;   % Valor inicial

            % --- Etiqueta y campo: Magnitud de cargas (-) -----------------
            app.MagnituddecargasLabel_3 = uilabel(app.UIFigure);
            app.MagnituddecargasLabel_3.Position = [26 51 73 30];
            app.MagnituddecargasLabel_3.Text = {'Magnitud '; 'de cargas (-)'};

            app.MagnitudQnEditField = uieditfield(app.UIFigure, 'numeric');
            app.MagnitudQnEditField.ValueChangedFcn = createCallbackFcn(app, @MagnitudQnEditFieldValueChanged, true);
            app.MagnitudQnEditField.HorizontalAlignment = 'center';
            app.MagnitudQnEditField.Position = [114 59 55 22];
            app.MagnitudQnEditField.Value = 2;

            % --- Etiqueta y slider: Longitud de línea (cargas +) ----------
            app.LongdelineaSliderLabel = uilabel(app.UIFigure);
            app.LongdelineaSliderLabel.HorizontalAlignment = 'center';
            app.LongdelineaSliderLabel.VerticalAlignment = 'top';
            app.LongdelineaSliderLabel.Position = [52 412 48 30];
            app.LongdelineaSliderLabel.Text = {'Long de'; 'linea'};

            app.LongQpSlider = uislider(app.UIFigure);
            app.LongQpSlider.Limits = [0 10];                 % Rango: de 0 a 10
            app.LongQpSlider.Orientation = 'vertical';
            app.LongQpSlider.ValueChangedFcn = createCallbackFcn(app, @LongQpSliderValueChanged, true);
            app.LongQpSlider.Step = 1;                        % Incremento de 1 en 1
            app.LongQpSlider.Position = [64 224 3 170];
            app.LongQpSlider.Value = 4;

            % --- Etiqueta y slider: Cantidad de cargas (+) ----------------
            app.CantcargasLabel = uilabel(app.UIFigure);
            app.CantcargasLabel.HorizontalAlignment = 'center';
            app.CantcargasLabel.VerticalAlignment = 'top';
            app.CantcargasLabel.Position = [117 412 63 30];
            app.CantcargasLabel.Text = {'Cant'; ' cargas (+)'};

            app.CantQpSlider = uislider(app.UIFigure);
            app.CantQpSlider.Limits = [2 50];                 % Mínimo 2 (para evitar dy = 0)
            app.CantQpSlider.Orientation = 'vertical';
            app.CantQpSlider.ValueChangedFcn = createCallbackFcn(app, @CantQpSliderValueChanged, true);
            app.CantQpSlider.Step = 1;
            app.CantQpSlider.Position = [143 224 3 170];
            app.CantQpSlider.Value = 20;

            % --- Etiqueta y slider: Cantidad de cargas (-) ----------------
            app.CantcargasLabel_2 = uilabel(app.UIFigure);
            app.CantcargasLabel_2.HorizontalAlignment = 'center';
            app.CantcargasLabel_2.VerticalAlignment = 'top';
            app.CantcargasLabel_2.Position = [765 412 60 30];
            app.CantcargasLabel_2.Text = {'Cant'; ' cargas (-)'};

            app.CantQnSlider = uislider(app.UIFigure);
            app.CantQnSlider.Limits = [2 50];
            app.CantQnSlider.Orientation = 'vertical';
            app.CantQnSlider.ValueChangedFcn = createCallbackFcn(app, @CantQnSliderValueChanged, true);
            app.CantQnSlider.Step = 1;
            app.CantQnSlider.Position = [789 224 3 170];
            app.CantQnSlider.Value = 20;

            % --- Etiqueta y slider: Longitud de línea (cargas -) ----------
            app.LongdelineaSlider_2Label = uilabel(app.UIFigure);
            app.LongdelineaSlider_2Label.HorizontalAlignment = 'center';
            app.LongdelineaSlider_2Label.VerticalAlignment = 'top';
            app.LongdelineaSlider_2Label.Position = [852 412 48 30];
            app.LongdelineaSlider_2Label.Text = {'Long de'; 'linea'};

            app.LongQnSlider = uislider(app.UIFigure);
            app.LongQnSlider.Limits = [0 10];
            app.LongQnSlider.Orientation = 'vertical';
            app.LongQnSlider.ValueChangedFcn = createCallbackFcn(app, @LongQnSliderValueChanged, true);
            app.LongQnSlider.Step = 1;
            app.LongQnSlider.Position = [864 224 3 170];
            app.LongQnSlider.Value = 4;

            % --- Etiqueta y campo: coordenada X del punto evaluado --------
            app.xEditFieldLabel = uilabel(app.UIFigure);
            app.xEditFieldLabel.HorizontalAlignment = 'right';
            app.xEditFieldLabel.Position = [681 15 25 22];
            app.xEditFieldLabel.Text = 'x:';

            app.xEditField = uieditfield(app.UIFigure, 'text');
            app.xEditField.ValueChangedFcn = createCallbackFcn(app, @xEditFieldValueChanged, true);
            app.xEditField.Position = [721 15 71 22];

            % --- Etiqueta y campo: número de puntos de la malla -----------
            app.NumdepuntosLabel = uilabel(app.UIFigure);
            app.NumdepuntosLabel.HorizontalAlignment = 'right';
            app.NumdepuntosLabel.Position = [759 69 90 22];
            app.NumdepuntosLabel.Text = 'Num de puntos:';

            app.NumPuntosEditField = uieditfield(app.UIFigure, 'numeric');
            app.NumPuntosEditField.ValueChangedFcn = createCallbackFcn(app, @NumPuntosEditFieldValueChanged, true);
            app.NumPuntosEditField.Position = [864 69 28 22];
            app.NumPuntosEditField.Value = 50;       % Valor inicial: malla de 50x50

            % --- Etiqueta y slider: distancia entre líneas de carga -------
            app.DistanciaSliderLabel = uilabel(app.UIFigure);
            app.DistanciaSliderLabel.HorizontalAlignment = 'right';
            app.DistanciaSliderLabel.Position = [187 92 54 22];
            app.DistanciaSliderLabel.Text = 'Distancia';

            app.DistanciaSlider = uislider(app.UIFigure);
            app.DistanciaSlider.Limits = [0 10];
            app.DistanciaSlider.ValueChangedFcn = createCallbackFcn(app, @DistanciaSliderValueChanged, true);
            app.DistanciaSlider.Position = [263 101 486 3];
            app.DistanciaSlider.Value = 2;

            % --- Etiqueta y campo: coordenada Y del punto evaluado --------
            app.yEditFieldLabel = uilabel(app.UIFigure);
            app.yEditFieldLabel.HorizontalAlignment = 'right';
            app.yEditFieldLabel.Position = [798 15 25 22];
            app.yEditFieldLabel.Text = 'y:';

            app.yEditField = uieditfield(app.UIFigure, 'text');
            app.yEditField.ValueChangedFcn = createCallbackFcn(app, @yEditFieldValueChanged, true);
            app.yEditField.Position = [838 15 71 22];

            % --- Etiqueta informativa "Magnitud del campo en:" ------------
            app.MagnituddelcampoenLabel = uilabel(app.UIFigure);
            app.MagnituddelcampoenLabel.Position = [744 39 133 22];
            app.MagnituddelcampoenLabel.Text = 'Magnitud del campo en:';

            % --- Mostrar la ventana una vez que todo está armado ----------
            app.UIFigure.Visible = 'on';
        end
    end

    % =====================================================================
    % CONSTRUCCIÓN Y DESTRUCCIÓN DE LA APLICACIÓN
    % =====================================================================
    methods (Access = public)

        function app = otrabes

            % Crear UIFigure y todos sus componentes
            createComponents(app)

            % Registrar la app con App Designer (necesario para callbacks)
            registerApp(app, app.UIFigure)

            % Si el usuario llama otrabes sin asignar el resultado a una
            % variable, se limpia para evitar fugas de memoria
            if nargout == 0
                clear app
            end
        end

        % -----------------------------------------------------------------
        % DESTRUCTOR: delete
        % -----------------------------------------------------------------
        % Se ejecuta automáticamente al cerrar la app. Asegura que la
        % ventana (UIFigure) se elimine correctamente.
        % -----------------------------------------------------------------
        function delete(app)
            delete(app.UIFigure)
        end
    end
end
