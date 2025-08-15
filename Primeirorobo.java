package teste;
import robocode.*;
import robocode.util.Utils;
import java.awt.Color;
import java.awt.geom.Point2D;

public class RoboBauer extends AdvancedRobot {
    private static final double WALL_MARGIN = 50; // Margem para evitar colisões com paredes
    private static final double MAX_BULLET_POWER = 3.0; // Potência máxima dos tiros
    private double previousEnergy = 100;
    private double radarDirection = 1;
    private double movementDirection = 1;
    private double gunHeat = 0;
    private int moveAmount = 100; // Distância do movimento

    public void run() {
        setColors(Color.red, Color.blue, Color.green); // Define as cores do robô
        setAdjustRadarForRobotTurn(true);
        setAdjustGunForRobotTurn(true);
        setAdjustRadarForGunTurn(true);
        setTurnRadarRight(360 * radarDirection); // Gira o radar continuamente

        while (true) {
            if (gunHeat == 0) {
                setTurnRadarRight(360 * radarDirection); // Gira o radar continuamente
                setAhead(moveAmount); // Movimento avançado
            }
            execute();
        }
    }

    public void onScannedRobot(ScannedRobotEvent e) {
        double bearing = e.getBearingRadians();
        double distance = e.getDistance();
        double enemyHeading = e.getHeadingRadians();
        double enemyVelocity = e.getVelocity();
        double bulletPower = Math.min(MAX_BULLET_POWER, getEnergy());
        double myX = getX();
        double myY = getY();
        double absoluteBearing = getHeadingRadians() + bearing;

        // Predição da posição futura do inimigo
        double predictedX = getX() + distance * Math.sin(absoluteBearing);
        double predictedY = getY() + distance * Math.cos(absoluteBearing);
        double deltaTime = 0;
        double battleFieldWidth = getBattleFieldWidth();
        double battleFieldHeight = getBattleFieldHeight();
        while ((++deltaTime) * (20 - bulletPower) < Point2D.distance(myX, myY, predictedX, predictedY)) {
            predictedX += Math.sin(enemyHeading) * enemyVelocity;
            predictedY += Math.cos(enemyHeading) * enemyVelocity;
            if (predictedX < WALL_MARGIN || predictedY < WALL_MARGIN || 
                predictedX > battleFieldWidth - WALL_MARGIN || predictedY > battleFieldHeight - WALL_MARGIN) {
                predictedX = Math.min(Math.max(WALL_MARGIN, predictedX), battleFieldWidth - WALL_MARGIN);
                predictedY = Math.min(Math.max(WALL_MARGIN, predictedY), battleFieldHeight - WALL_MARGIN);
                break;
            }
        }

        double theta = Utils.normalAbsoluteAngle(Math.atan2(predictedX - getX(), predictedY - getY()));
        setTurnRadarRightRadians(Utils.normalRelativeAngle(absoluteBearing - getRadarHeadingRadians()));
        setTurnGunRightRadians(Utils.normalRelativeAngle(theta - getGunHeadingRadians()));

        // Ajuste da potência de tiro com base na distância
        if (distance < 150) {
            fire(bulletPower);
        }

        // Estratégia de movimentação evasiva
        if (distance < 100) {
            movementDirection = -movementDirection; // Inverte a direção para evasão
            setAhead(100 * movementDirection); // Movimento para frente ou para trás
            setTurnRight(30 * movementDirection); // Ajusta o ângulo para mudar a trajetória
        } else {
            setAhead(moveAmount); // Movimento padrão para frente
        }

        // Atualiza a energia do inimigo
        previousEnergy = e.getEnergy();

        // Ajuste da direção do radar para manter o inimigo na mira
        radarDirection = -radarDirection;
    }

    public void onHitByBullet(HitByBulletEvent e) {
        // Evasão ao ser atingido
        movementDirection = -movementDirection;
        setAhead(100 * movementDirection);
        setTurnRight(90 * movementDirection);
    }

    public void onHitWall(HitWallEvent e) {
        // Ajusta o movimento ao bater na parede
        movementDirection = -movementDirection;
        setAhead(100 * movementDirection);
        setTurnRight(90 * movementDirection);
    }
}
