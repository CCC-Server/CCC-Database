--G.Rock 세트
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,s.pfil1,nil,2,nil,nil,nil,nil,false,s.pfun1)
	
	-- ①: 이 카드를 특수 소환했을 경우, 또는 이 카드가 묘지로 보내졌을 경우
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.tar1)
	e1:SetOperation(s.op1)
	c:RegisterEffect(e1)
	local e2=e1:Clone()
	e2:SetCode(EVENT_TO_GRAVE)
	c:RegisterEffect(e2)
	
	-- ②: 자신 / 상대 턴에 덱 / 엑스트라 덱에서 "G.Rock" 카드 1장을 묘지로 보내거나 자신 필드의 엑시즈 몬스터 1장의 소재로 한다.
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.tar3)
	e3:SetOperation(s.op3)
	c:RegisterEffect(e3)
end

function s.pfil1(c,xc,st,p)
	return c:IsXyzLevel(xc,9) or c:IsRank(9)
end
function s.pfun1(g,tp,xc)
	return g:FilterCount(Card.IsXyzLevel,nil,xc,9)==#g or g:FilterCount(Card.IsRank,nil,9)==#g
end
function s.tar1(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_MZONE) and chkc:IsFaceup()
	end
	if chk==0 then
		return Duel.IsExistingTarget(Card.IsFaceup,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.SelectTarget(tp,Card.IsFaceup,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.op1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and tc:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DOUBLE_XYZ_MATERIAL)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		e1:SetValue(1)
		e1:SetOperation(function(e,c)
			return c:IsRank(9)
		end)
		tc:RegisterEffect(e1)
	end
end

-- ②번 효과 처리용 카드군 필터
function s.tfil3(c)
	return c:IsSetCard(0xfa6)
end

-- 자신 필드의 앞면 표시 엑시즈 몬스터 판정 필터
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_XYZ)
end

-- ②번 효과 타겟: 덱 / 엑스트라 덱에 카드군 카드가 존재하기만 하면 발동 가능
function s.tar3(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tfil3,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK+LOCATION_EXTRA)
end

-- ②번 효과 오퍼레이션
function s.op3(e,tp,eg,ep,ev,re,r,rp)
	-- 1. 덱 / 엑스트라 덱에서 카드를 딱 1장 고름
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local sg=Duel.SelectMatchingCard(tp,s.tfil3,tp,LOCATION_DECK+LOCATION_EXTRA,0,1,1,nil)
	if #sg==0 then return end
	local tc=sg:GetFirst()
	
	-- 2. 자신 필드에 소재를 충전할 수 있는 엑시즈 본체가 존재하는지 검증
	local b1=tc:IsAbleToGrave()
	local b2=Duel.IsExistingMatchingCard(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
	
	-- 옵션 선택창 띄우기 (0번: 묘지로 보낸다 / 1번: 자신 필드의 엑시즈 몬스터의 소재로 한다)
	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,0)},
		{b2,aux.Stringid(id,1)})
		
	if op==1 then
		-- 묘지로 보내는 처리
		Duel.SendtoGrave(tc,REASON_EFFECT)
	elseif op==2 then
		-- 소재로 넣을 자신 필드의 엑시즈 몬스터를 최종 1장 타겟 지정
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
		local xyzg=Duel.SelectMatchingCard(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
		local xyz_monster=xyzg:GetFirst()
		
		if xyz_monster then
			Duel.Overlay(xyz_monster,tc) -- 찐빠 방지 순정 인자 규격 적용
		else
			-- 만약 그 사이에 엑시즈 몬스터가 필드에서 사라졌다면 유희왕 룰 재정에 의해 묘지로 보내짐
			Duel.SendtoGrave(tc,REASON_EFFECT)
		end
	end
end