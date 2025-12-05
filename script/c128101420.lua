--호루스 지속 마법 (가칭)
local s,id=GetID()
local SET_HORUS=0x1003  -- "Horus the Black Flame Dragon" 카드군

function s.initial_effect(c)
	--------------------------------------
	-- 항상 "호루스의 흑염룡" 카드로 취급
	--------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetRange(LOCATION_ALL)
	e0:SetValue(SET_HORUS)
	c:RegisterEffect(e0)

	--------------------------------------
	-- 패/필드에서의 발동 (Continuous Spell 기본 발동)
	--------------------------------------
	local eAct=Effect.CreateEffect(c)
	eAct:SetType(EFFECT_TYPE_ACTIVATE)
	eAct:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(eAct)

	--------------------------------------
	-- (1) 메인 페이즈에 호루스 몬스터 서치/회수
	--------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1,id)  -- (1)(2)(3) 공유 HOPT
	e1:SetCondition(s.thcon1)
	e1:SetTarget(s.thtg1)
	e1:SetOperation(s.thop1)
	c:RegisterEffect(e1)

	--------------------------------------
	-- (2) 상대가 마법 카드를 발동했을 때 : 상대 몬스터 전부 뒷면 수비
	--------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_POSITION)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,{id,1})  -- (1)(2)(3) 공유 HOPT
	e2:SetCondition(s.poscon2)
	e2:SetTarget(s.postg2)
	e2:SetOperation(s.posop2)
	c:RegisterEffect(e2)

	--------------------------------------
	-- (3) 데미지 스텝 종료시, 호루스가 공격했다면
	--     이 카드를 묘지로 보내고 그 몬스터가 한 번 더 공격
	--------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_TOGRAVE)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DAMAGE_STEP_END)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,{id,2})  -- (1)(2)(3) 공유 HOPT
	e3:SetCondition(s.atkcon3)
	e3:SetCost(s.atkcost3)
	e3:SetTarget(s.atktg3)
	e3:SetOperation(s.atkop3)
	c:RegisterEffect(e3)
end

--------------------------------------
-- (1) 메인 페이즈 조건
--------------------------------------
function s.thcon1(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.thfilter1(c)
	return c:IsSetCard(SET_HORUS) and c:IsMonster() and c:IsAbleToHand()
end
function s.thtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
function s.thop1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter1,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

--------------------------------------
-- (2) 상대 마법 발동시 : 상대 몬스터 전부 뒷면 수비
--------------------------------------
function s.poscon2(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp
		and re:IsActiveType(TYPE_SPELL)
		and re:IsHasType(EFFECT_TYPE_ACTIVATE)
end
function s.posfilter(c)
	return c:IsFaceup() and c:IsCanTurnSet()
end
function s.postg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.posfilter,tp,0,LOCATION_MZONE,1,nil)
	end
	local g=Duel.GetMatchingGroup(s.posfilter,tp,0,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,#g,0,0)
end
function s.posop2(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.posfilter,tp,0,LOCATION_MZONE,nil)
	if #g>0 then
		Duel.ChangePosition(g,POS_FACEDOWN_DEFENSE)
	end
end

--------------------------------------
-- (3) 공격 후 2번째 공격 효과
--------------------------------------
function s.atkcon3(e,tp,eg,ep,ev,re,r,rp)
	local a=Duel.GetAttacker()
	return a and a:IsControler(tp)
		and a:IsSetCard(SET_HORUS)
		and a:IsRelateToBattle()
end
function s.atkcost3(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsAbleToGraveAsCost() end
	Duel.SendtoGrave(c,REASON_COST)
end
function s.atktg3(e,tp,eg,ep,ev,re,r,rp,chk)
	local a=Duel.GetAttacker()
	if chk==0 then return a and a:IsRelateToBattle() and a:IsFaceup() end
	e:SetLabelObject(a)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,e:GetHandler(),1,0,0)
end
function s.atkop3(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if not tc or not tc:IsRelateToBattle() or not tc:IsFaceup() then return end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_EXTRA_ATTACK_MONSTER)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_BATTLE)
	tc:RegisterEffect(e1)
end
