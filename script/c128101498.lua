-- CNo.73 격룡신 어비스 엠페러
local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환
	c:EnableReviveLimit()
	Xyz.AddProcedure(c,nil,6,3,s.ovfilter,aux.Stringid(id,0))
	
	-- ①: 공격력 배가 + 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E+TIMING_MAIN_END+TIMING_BATTLE_START)
	e1:SetCost(s.atkcost)
	e1:SetOperation(s.atkop)
	c:RegisterEffect(e1)
	
	-- ②: 특수 소환 몬스터 무력화 (No.73 소재 시)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,2))
	e2:SetCategory(CATEGORY_ATKCHANGE+CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.discon)
	e2:SetTarget(s.distg)
	e2:SetOperation(s.disop)
	c:RegisterEffect(e2)
end
s.listed_names={36076683} -- No.73 격룡신 어비스 스플래시

-- [엑시즈 소환 필터 수정됨]
function s.ovfilter(c,tp,lc)
	-- c:IsCode는 카드 번호만 인자로 받아야 합니다. 
	-- lc(소환될 엑시즈 몬스터)가 No.73으로 취급되는지 확인하기 위해 IsSummonCode를 사용합니다.
	return c:IsFaceup() and c:IsSummonCode(lc,SUMMON_TYPE_XYZ,tp,36076683)
end

-- [효과 ①: 공격력 배가 및 파괴]
function s.atkcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,1,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,1,1,REASON_COST)
end

function s.desfilter(c,atk)
	return c:IsFaceup() and c:IsAttackBelow(atk-1)
end

function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsFaceup() and c:IsRelateToEffect(e) then
		local curr_atk=c:GetAttack()
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(curr_atk*2)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_DISABLE+RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
		c:RegisterEffect(e1)
		
		-- 공격력이 올랐다면 그 차이(상승치=원래 공격력)만큼 낮은 몬스터 파괴
		if c:GetAttack() > curr_atk then
			local diff=c:GetAttack()-curr_atk
			local g=Duel.GetMatchingGroup(s.desfilter,tp,0,LOCATION_MZONE,nil,diff)
			if #g>0 then
				Duel.BreakEffect()
				Duel.Destroy(g,REASON_EFFECT)
			end
		end
	end
end

-- [효과 ②: 무력화]
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	-- 소재에 No.73이 있고, 상대가 몬스터를 특수 소환했을 때
	return e:GetHandler():GetOverlayGroup():IsExists(Card.IsCode,1,nil,36076683)
		and eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
end

function s.distg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return eg:IsContains(chkc) and chkc:IsControler(1-tp) and chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return eg:IsExists(Card.IsCanBeEffectTarget,1,nil,e) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=eg:FilterSelect(tp,Card.IsCanBeEffectTarget,1,1,nil,e)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,1,0,0)
end

function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		-- 다음 턴 종료시까지 (RESET_PHASE+PHASE_END, 2)
		local r_flags = RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END
		local r_count = 2
		
		-- 공격력 0
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(0)
		e1:SetReset(r_flags, r_count)
		tc:RegisterEffect(e1)
		
		-- 공격 불가
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_CANNOT_ATTACK)
		e2:SetReset(r_flags, r_count)
		tc:RegisterEffect(e2)
		
		-- 효과 무효
		local e3=Effect.CreateEffect(c)
		e3:SetType(EFFECT_TYPE_SINGLE)
		e3:SetCode(EFFECT_DISABLE)
		e3:SetReset(r_flags, r_count)
		tc:RegisterEffect(e3)
		local e4=Effect.CreateEffect(c)
		e4:SetType(EFFECT_TYPE_SINGLE)
		e4:SetCode(EFFECT_DISABLE_EFFECT)
		e4:SetReset(r_flags, r_count)
		tc:RegisterEffect(e4)
	end
end