-- 네메시스 디스트로이돌 펜듈럼 몬스터
local s,id=GetID()
function s.initial_effect(c)
	-- 카드명 1턴 1회 제한
	c:SetUniqueOnField(1,0,id)

	-- 펜듈럼
	Pendulum.AddProcedure(c)

	------------------------------------------------------
	-- [펜듈럼 효과] ①
	------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_EXTRA_FUSION_MATERIAL)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(LOCATION_PZONE,0)
	e1:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0x765))
	e1:SetValue(s.mfusval)
	c:RegisterEffect(e1)

	------------------------------------------------------
	-- [몬스터 효과] ① 융합 소재로 묘지/엑스트라 덱 이동 시
	------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)

	------------------------------------------------------
	-- [몬스터 효과] ② 효과로 파괴 시 상대 데미지 + 펜듈럼 존 이동
	------------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(s.damcon)
	e3:SetTarget(s.damtg)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end

-- ======================================
-- 펜듈럼 효과: 펜듈럼 존 소재도 융합 소재로 사용 가능
-- ======================================
function s.mfusval(e,c,fc,sub,mg,sg)
	if not c:IsSetCard(0x765) then return false end
	return true
end

-- ======================================
-- 몬스터 효과 ① 조건
-- ======================================
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_FUSION+REASON_MATERIAL) or c:IsLocation(LOCATION_EXTRA)
end

function s.thfilter(c)
	return c:IsSetCard(0x765) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_GRAVE)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- ======================================
-- 몬스터 효과 ② 조건
-- ======================================
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsReason(REASON_EFFECT)
end

function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(500)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,500)
end

function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)

	-- 엑스트라 덱에서 신약 백의 노래 찾기 (앞면 표시)
	local g=Duel.GetMatchingGroup(function(c)
		return c:IsCode(128770335) and c:IsFaceup() and c:IsLocation(LOCATION_EXTRA)
	end, tp, LOCATION_EXTRA, 0, nil)

	if #g>0 then
		local seq=0
		if Duel.CheckLocation(tp,LOCATION_PZONE,0) then seq=0
		elseif Duel.CheckLocation(tp,LOCATION_PZONE,1) then seq=1
		else return end
		local tc=g:GetFirst()
		Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end

