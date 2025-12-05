--Armed Dragon Thunder Bolt
local s,id=GetID()
function s.initial_effect(c)
	-- Xyz 소환
	c:EnableReviveLimit()
	-- 소재: 레벨 7 몬스터 2장
	Xyz.AddProcedure(c,nil,7,2)

	------------------------------------------------
	-- ① 1턴에 1번, 소재 1개 떼고 상대 카드 1장 파괴,
	--	그 코스트가 "Armed Dragon"이면 1장 드로우
	------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetCountLimit(1) -- 이 카드 1장당 1턴에 1번
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)

	------------------------------------------------
	-- ② "Armed Dragon"을 소재로 가지고 있는 동안 직접 공격 가능
	------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DIRECT_ATTACK)
	e2:SetCondition(s.dircon)
	c:RegisterEffect(e2)

	------------------------------------------------
	-- ③ 이 카드가 묘지로 보내졌을 때
	--	묘지의 "Armed Dragon" 1장을 패로
	------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOHAND)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetTarget(s.thtg)
	e3:SetOperation(s.thop)
	c:RegisterEffect(e3)
end

------------------------------------------------
-- 공통용 필터 ("Armed Dragon" 세트코드)
-- ⚠ 세트코드 0x111 은 DB에 맞게 조정 가능
------------------------------------------------
function s.adfilter(c)
	return c:IsSetCard(0x111)
end

------------------------------------------------
-- ① 비용 / 대상 / 처리
------------------------------------------------
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then 
		return c:CheckRemoveOverlayCard(tp,1,1,REASON_COST)
	end
	-- 코스트 지불 전에, 소재 중에 "Armed Dragon"이 있었는지 체크해서 라벨로 저장
	local og=c:GetOverlayGroup()
	if og:IsExists(s.adfilter,1,nil) then
		e:SetLabel(1)
	else
		e:SetLabel(0)
	end
	-- 실제로 소재 1장 떼기 (디태치)
	c:RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsDestructable()
	end
	if chk==0 then 
		return Duel.IsExistingTarget(Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsDestructable,tp,0,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	-- 드로우는 나중에 코스트 체크 후 처리
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.Destroy(tc,REASON_EFFECT)~=0 and e:GetLabel()==1 then
		-- 코스트로 "Armed Dragon"이 있었을 경우 1드로우
		if Duel.IsPlayerCanDraw(tp,1) then
			Duel.BreakEffect()
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	end
end

------------------------------------------------
-- ② 소재 중에 "Armed Dragon"이 있을 때 직접 공격
------------------------------------------------
function s.dircon(e)
	local c=e:GetHandler()
	local og=c:GetOverlayGroup()
	return og:IsExists(s.adfilter,1,nil)
end

------------------------------------------------
-- ③ 묘지로 보내졌을 때, 묘지의 "Armed Dragon" 1장 패로
------------------------------------------------
function s.thfilter(c)
	return c:IsSetCard(0x111) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.thfilter(chkc)
	end
	if chk==0 then 
		return Duel.IsExistingTarget(s.thfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectTarget(tp,s.thfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end
end
