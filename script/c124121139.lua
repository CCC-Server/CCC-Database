-- 버서크 데먼 드래곤
local s,id=GetID()
function s.initial_effect(c)
	-- 특수 소환 몬스터 제약 (통상 소환 불가)
	c:EnableReviveLimit()
	
	-- "데몬과의 거래(6850209)"의 효과로만 특수 소환할 수 있다
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- ①: 패의 이 카드와 패의 "데몬" 카드 1장을 보여주고 2장 드로우, 2장 덱으로 되돌림
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	-- 1턴에 2번 제약
	e1:SetCountLimit(2,id)
	e1:SetCost(s.drcost)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- ②: 자신 / 상대 메인 페이즈에, 상대 필드의 카드 2장 대상. 자신 패/필드의 앞면 표시 데몬 1장과 대상 파괴, 공격력 500 다운
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(2,id+1)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END)
	e2:SetCondition(s.descon)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end
s.listed_names={6850209, 85605684} -- 데몬과의 거래, 버서크 데드 드래곤
s.listed_series={0x45} -- 데몬

-- [소환 조건 필터] "데몬과의 거래"인지 확인
function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(6850209)
end

-- [① 코스트 필터] 패에서 보여줄 이 카드 이외의 다른 "데몬" 카드
function s.cfilter(c)
	return c:IsSetCard(0x45) and not c:IsPublic()
end

-- [① 코스트]
function s.drcost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return not c:IsPublic() and Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_HAND,0,1,c) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_HAND,0,1,1,c)
	g:AddCard(c)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
end

-- [① 타겟 지정]
function s.drtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp,2) end
	Duel.SetTargetPlayer(tp)
	Duel.SetTargetParam(2)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,2,tp,LOCATION_HAND)
end

-- [① 효과 처리]
function s.drop(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	if Duel.Draw(p,d,REASON_EFFECT)==2 then
		Duel.ShuffleHand(tp)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,Card.IsAbleToDeck,tp,LOCATION_HAND,0,2,2,nil)
		if g:GetCount()>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

-- [② 발동 조건] 메인 페이즈 전용
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end

-- [② 내 패/필드의 데몬 파괴 필터] (패에 있거나 필드 앞면 표시)
function s.desfilter_my(c)
	return c:IsSetCard(0x45) and (c:IsLocation(LOCATION_HAND) or c:IsFaceup())
end

-- [② 타겟 지정] (상대 필드 2장만 대상)
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsOnField() end
	if chk==0 then 
		return Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,2,nil)
		and Duel.IsExistingMatchingCard(s.desfilter_my,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,nil) 
	end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	-- 상대 필드의 카드 2장 대상 지정
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,2,2,nil)
	
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,3,tp,LOCATION_HAND+LOCATION_ONFIELD)
end

-- [② 효과 처리]
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	
	-- 효과 처리 시점에 내 패/필드의 "데몬" 카드 1장을 고름 (비대상)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local my_g=Duel.SelectMatchingCard(tp,s.desfilter_my,tp,LOCATION_HAND+LOCATION_ONFIELD,0,1,1,nil)
	
	if my_g:GetCount()>0 then
		-- 선택한 내 카드와 대상 지정된 상대 카드를 그룹으로 합침
		tg:Merge(my_g)
		
		-- 동시 파괴 처리
		if Duel.Destroy(tg,REASON_EFFECT)>0 then
			local c=e:GetHandler()
			if c:IsRelateToEffect(e) and c:IsFaceup() then
				local e1=Effect.CreateEffect(c)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_UPDATE_ATTACK)
				e1:SetValue(-500)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
				c:RegisterEffect(e1)
			end
		end
	end
end